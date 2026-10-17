#!/bin/bash
set -euo pipefail
readonly SOURCE_REV=fb58e0dbc8399662c0e47c76578c6e878b14f6cf
readonly SOURCE_SHA=0e1d7e8fbb50eebfdb28b60dcff029bfa371215958d59605825746713a0ef034
readonly LLAMA_REV=3cf03257f219afbe7334045ff7c6a06ac68c627d
readonly LLAMA_SHA=c076d7534afa0e5d0ec2a0d425b11e791c16f3de0d727221aea071cef156a280
readonly MODEL_DIR=/selected-model
model_id="${STRATA_MODEL_ID:-orca-q4-k-s}"
pack_name="${STRATA_PACK_NAME:-orca-q4_k_s}"
min_vram_mib="${STRATA_MIN_VRAM_MIB:-15360}"
[[ "$model_id" =~ ^[a-z0-9-]+$ && "$pack_name" =~ ^[a-z0-9_-]+$ && "$min_vram_mib" =~ ^[0-9]{1,6}$ ]]
readonly PACK="data/packs/$pack_name"
readonly MANIFEST="data/offgrid/$model_id.tsv"
log() {
	printf '{"time":"%s","level":"%s","file":"setup-container.sh","line":%d,"func":"main","msg":"%s"}\n' \
		"$(date -u +%FT%TZ)" "$1" "${BASH_LINENO[0]}" "$2" >&2
}
trap 'log ERROR "Setup failed. For HTTP 401/403, accept model access on Hugging Face and export HF_TOKEN. Rerun to resume."' ERR
exec > >(tee -a setup.log) 2>&1
[[ "$PWD" == /data/bw/qwen-strata && -r /support/models.json ]]
[[ -z "${DEBUG:-}" ]] || log DEBUG 'Setup started'
vram_mib="$(nvidia-smi --id=0 --query-gpu=memory.total --format=csv,noheader,nounits)"
[[ "$vram_mib" =~ ^[0-9]+$ && "$vram_mib" -ge "$min_vram_mib" ]] || {
	log ERROR 'GPU 0 does not meet the selected preset VRAM requirement'
	exit 1
}
arch="$(nvidia-smi --id=0 --query-gpu=compute_cap --format=csv,noheader | tr -d '.')"
[[ "$arch" =~ ^(75|80|86|89|90)$ ]] || {
	log ERROR 'GPU architecture needs a different CUDA/toolchain profile; see the upstream setup guide'
	exit 1
}
if [[ -s /support/setup.py && ! -s .offgrid-source-ready ]]; then
	log INFO 'Reusing the existing source tree without overwriting it'
elif [[ ! -s .offgrid-source-ready ]]; then
	log INFO 'Downloading checksum-pinned Strata source'
	curl -fSL --retry 3 "https://codeload.github.com/Niko1221/Strata/tar.gz/$SOURCE_REV" -o source.tar.gz
	printf '%s  source.tar.gz\n' "$SOURCE_SHA" | sha256sum -c -
	tar -xzf source.tar.gz --strip-components=1
	printf '%s\n' "$SOURCE_REV" >.offgrid-source-ready
fi
if [[ -s /support/setup.py && -s third_party/llama.cpp/ggml/CMakeLists.txt ]]; then
	log INFO 'Reusing existing llama.cpp source'
elif [[ ! -s .offgrid-llama-ready ]]; then
	curl -fSL --retry 3 "https://codeload.github.com/ggml-org/llama.cpp/tar.gz/$LLAMA_REV" -o llama.tar.gz
	printf '%s  llama.tar.gz\n' "$LLAMA_SHA" | sha256sum -c -
	mkdir -p third_party/llama.cpp
	tar -xzf llama.tar.gz --strip-components=1 -C third_party/llama.cpp
	printf '%s\n' "$LLAMA_REV" >.offgrid-llama-ready
fi
if [[ ! -x .venv/bin/python ]]; then python3 -m venv .venv; fi
export PATH="$PWD/.venv/bin:/usr/local/cuda/bin:$PATH"
python -m pip install --require-hashes -r /support/requirements.lock
first=''
while read -r hash expected_bytes filename url; do
	[[ "$hash" =~ ^[[:xdigit:]]{64}$ && "$expected_bytes" =~ ^[0-9]+$ && "$filename" =~ ^[A-Za-z0-9._-]+\.gguf$ && "$url" == https://huggingface.co/* ]]
	if [[ -z "$first" ]]; then first="$filename"; fi
	if [[ -s "$MODEL_DIR/$filename" ]]; then
		printf '%s  %s\n' "$hash" "$MODEL_DIR/$filename" | sha256sum -c -
		continue
	fi
	log INFO 'Downloading model shard; interrupted files resume on the next run'
	curl -fSL --retry 3 --continue-at - \
		--header @<(if [[ -n "${HF_TOKEN:-}" ]]; then printf 'Authorization: Bearer %s\n' "$HF_TOKEN"; fi) \
		"$url" -o "$MODEL_DIR/$filename.part"
	printf '%s  %s\n' "$hash" "$MODEL_DIR/$filename.part" | sha256sum -c -
	mv "$MODEL_DIR/$filename.part" "$MODEL_DIR/$filename"
done <"$MANIFEST"
unset HF_TOKEN
if [[ ! -x engine/strata ]]; then
	log INFO 'Compiling Strata for the installed GPU with two build workers'
	cmake -S . -B build-offgrid -G Ninja -DCMAKE_BUILD_TYPE=Release \
		-DSTRATA_ENABLE_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="$arch" \
		-DSTRATA_BUILD_TESTS=OFF -DSTRATA_GGML_DIR="$PWD/third_party/llama.cpp"
	cmake --build build-offgrid --parallel 2 --target strata
	mkdir -p engine
	install -m 755 build-offgrid/strata engine/strata.part
	mv engine/strata.part engine/strata
fi
if [[ ! -s "$PACK/native_experts.txt" || ! -s "$PACK/tokenizer/vocab.json" ]]; then
	python tools/iq_pack.py --gguf "$MODEL_DIR/$first" \
		--out "$PACK" --compat-bf16
fi
if [[ ! -s data/mtp/rt/experts.bin ]]; then
	python tools/mtp_fetch.py fetch --out data/mtp
	python tools/mtp_pack.py --src data/mtp --experts q2_0 --out data/mtp/mtp-q2_0.gguf
	python tools/mtp_rt.py --gguf data/mtp/mtp-q2_0.gguf --out data/mtp/rt
fi
if [[ ! -s data/mtp/rt/draft_vocab.bin ]]; then
	cp data/draft_vocab.bin data/mtp/rt/draft_vocab.bin
fi
log INFO 'Strata setup complete'
