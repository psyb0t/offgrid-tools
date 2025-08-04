#!/bin/bash
cp /usr/share/OVMF/OVMF_VARS_4M.fd ./OVMF_VARS.fd

qemu-system-x86_64 \
    -enable-kvm \
    -m 16G \
    -cpu host \
    -smp 8 \
    -machine type=q35 \
    -boot d \
    -drive file=offgrid-ubuntu.qcow2,format=qcow2,if=virtio \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=./OVMF_VARS.fd \
    -device qxl-vga \
    -display spice-app,gl=on,show-cursor=on \
    -device virtio-serial-pci \
    -chardev spicevmc,id=ch1,name=vdagent \
    -device virtserialport,chardev=ch1,name=com.redhat.spice.0 \
    -chardev socket,path=/tmp/qga.sock,server=on,wait=off,id=qga0 \
    -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0
