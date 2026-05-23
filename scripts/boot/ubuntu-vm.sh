#!/data/data/com.termux/files/usr/bin/bash
# Termux:Boot — démarre la VM Ubuntu automatiquement au boot du téléphone.
# Adapter VMSDIR et FIXDIR à votre setup.
# Placer dans ~/.termux/boot/ubuntu-vm.sh (s'exécute après kvm_fix.sh)

termux-wake-lock

VMSDIR="/data/data/com.termux/files/home/vms"
FIXDIR="/data/data/com.termux/files/home/projects/kvm-lineageos/kvm_reg_fix"
LOGFILE="$VMSDIR/ubuntu-vm.log"

until [ -w /dev/kvm ]; do sleep 2; done

env LD_PRELOAD="$FIXDIR/kvm_reg_fix4.so" \
  qemu-system-aarch64 \
    -machine virt,accel=kvm \
    -cpu host,pmu=off \
    -m 4096 \
    -smp 6 \
    -drive if=pflash,format=raw,readonly=on,file="/data/data/com.termux/files/usr/share/qemu/edk2-aarch64-code.fd" \
    -drive if=pflash,format=raw,file="$VMSDIR/ubuntu-vars.fd" \
    -drive file="$VMSDIR/ubuntu.qcow2",format=qcow2,if=virtio,cache=writeback \
    -nographic \
    -serial none \
    -monitor none \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443 \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-rng-pci \
    >> "$LOGFILE" 2>&1 &

echo "$(date): Ubuntu VM démarrée (PID $!)" >> "$LOGFILE"
