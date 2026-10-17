# Strata in offgrid-tools

Choose a preset before the first download:

```bash
./strata/run.sh --list-models
./strata/run.sh --model qwen-iq2-xs
```

On a fresh interactive run, `./strata/run.sh` asks for a model ID. Scripts must pass `--model` the first time. Successful setup saves the choice and limits in gitignored `strata/settings.json`. Later runs use those settings. The existing root-level uncensored Q4 installation remains the default on machines that already have it.

## Supported presets

| ID | Model | Download | Suggested system |
| --- | --- | ---: | --- |
| `qwen-q2-0` | Flash-Next Q2_0 | 66.4 GB | 48 GB RAM, 12 GB NVIDIA GPU |
| `qwen-iq2-xs` | Flash-Next IQ2_XS | 68.0 GB | 48 GB RAM, 12 GB NVIDIA GPU |
| `qwen-iq3-s` | Flash-Next IQ3_S | 83.6 GB | 64 GB RAM, 12 GB NVIDIA GPU |
| `orca-q4-k-s` | Flash-Next Uncensored Q4_K_S | 111.8 GB | 128 GB RAM, 16 GB NVIDIA GPU |

The smaller downloads are lower-precision versions of the same large Flash-Next model, not smaller parameter-count models. The Qwen presets use the original weights; only the Orca preset is the uncensored fine-tune. Support for the three original quantizations comes from the pinned upstream installer. Their defaults are starting limits, not performance or accuracy measurements on every machine. The uncensored Q4 preset was tested on an RTX A5000 Laptop with 128 GB RAM.

This Strata engine does not accept arbitrary architectures such as a 7B GGUF, Gemma or GLM. Use llama.cpp or a separately configured PolyStrata installation for those.

## Setup and requirements

First run builds the CUDA environment, downloads checksum-pinned source, installs hash-locked Python dependencies in Docker, fetches only the selected weights, compiles the engine and prepares its pack. The engine and MTP runtime are shared; each preset has a separate pack and generated configuration.

The host needs Linux x86-64, Docker with Compose v2 and NVIDIA Container Toolkit, Bash, jq and flock. GPU 0 is selected. CUDA architectures 75, 80, 86, 89 and 90 are supported by this wrapper; Blackwell needs a newer toolchain profile. AMD needs an upstream setup outside this wrapper.

Initial setup needs internet and enough disk for the remaining model bytes plus 32 GiB for runtime, MTP, build and image files. Partial downloads count toward the completed bytes. Setup is capped at two CPUs and 16 GiB RAM. Serving uses the selected preset's limits.

## Change limits

```bash
./strata/run.sh --model qwen-iq2-xs --context 65536 --cpus 6 --port 8090
./strata/run.sh --model orca-q4-k-s --context 262144 --memory-gib 88 --resident-gib 68
./strata/run.sh --help
```

Context ranges from 512 to 262144 tokens. `--memory-gib` caps container RAM; `--resident-gib` sets the expert RAM budget and must leave at least 8 GiB under that cap. The RAM cap must also leave at least 8 GiB for the host. `--cpus` sets the container CPU quota, not an exact engine thread count. `--vram-reserve-mib` leaves VRAM free for the desktop.

The original-weight presets start at 32K context. The tested uncensored preset starts at 256K. Avoid running another large model alongside Strata.

CLI values override exported environment values, then saved settings, then preset defaults. See [the environment example](../.env.example) for supported variables. The launcher does not source environment files as shell code. Switching to a different model ID takes that preset's defaults unless overridden; each successful choice replaces the saved selection.

## Model access

For the uncensored preset, accept the conditions on [the model repository](https://huggingface.co/orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF) and provide a read token with access:

```bash
read -rsp 'Hugging Face token: ' HF_TOKEN; printf '\n'
export HF_TOKEN
./strata/run.sh --model orca-q4-k-s
unset HF_TOKEN
```

The token is used only by setup, never saved in the image, configuration or settings. An HTTP 401/403 means the account or token lacks access. The wrapper does not read an `hf login` token file automatically.

## Reuse GGUF files

```bash
./strata/run.sh --model qwen-iq2-xs --gguf-dir '/mnt/models/Flash-Next IQ2_XS'
```

The directory must contain every shard listed for that preset in `models.json`, with the original filenames and matching SHA256. It is mounted read-only, no weights are copied into the repository, and missing or mismatched files fail before startup. Source, dependencies and MTP may still need downloading on first setup. External shards are checksum-checked on each launch, which can take minutes for a large model.

Without `--gguf-dir`, weights go in the selected subdirectory under `models/gguf/`, shared with llama.cpp. Different quantizations have their own directories; installing multiple presets consumes additional disk.

## Commands and storage

```bash
./strata/run.sh --model qwen-iq2-xs --setup-only
./strata/run.sh --offline
docker compose logs -f strata
docker compose stop strata
```

New source, engine, Python environment, packs and MTP go in `strata/runtime/`. Existing installations directly in `strata/` are reused without moving files. Host paths are mapped to fixed container paths, so new checkouts do not need a host compatibility symlink.

Normal `docker compose up` skips Strata. Use the launcher to select the correct mounts and limits. The browser UI and API bind to localhost, port 8080 unless changed. No automatic startup on reboot or API requests.

## Offline copy

After setup:

```bash
./save-docker-images.sh --strata-only
```

Copy the repository, `strata/settings.json`, the entire installed runtime, the selected shared GGUF directory and the image tar plus SHA256 sidecar under `docker-images/`. Preserve permissions and symlinks. External GGUF directories must also be available; pass a new `--gguf-dir` if their path changes.

On the destination:

```bash
./load-docker-images.sh --strata-only
./strata/run.sh --offline
```

The image contains the system environment, not the mounted Python environment, source or weights. A different GPU architecture may require an engine rebuild.

Back to the [project README](../README.md).
