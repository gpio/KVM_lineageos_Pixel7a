#!/data/data/com.termux/files/usr/bin/bash
# Lance une VM Ubuntu Server arm64 avec KVM sur Android/LineageOS.
# Adapter les chemins à votre setup.

VMSDIR="$(dirname "$(realpath "$0")")/../vms"
FIXDIR="$(dirname "$(realpath "$0")")/../kvm_reg_fix"
QEMU_BIOS="/data/data/com.termux/files/usr/share/qemu/edk2-aarch64-code.fd"

exec env LD_PRELOAD="$FIXDIR/kvm_reg_fix4.so" \
  qemu-system-aarch64 \
    -machine virt,accel=kvm \
    -cpu host,pmu=off \
    -m 4096 \
    -smp 6 \
    -drive if=pflash,format=raw,readonly=on,file="$QEMU_BIOS" \
    -drive if=pflash,format=raw,file="$VMSDIR/ubuntu-vars.fd" \
    -drive file="$VMSDIR/ubuntu.qcow2",format=qcow2,if=virtio,cache=writeback \
    -nographic \
    -serial mon:stdio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443 \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-rng-pci \
    "$@"
