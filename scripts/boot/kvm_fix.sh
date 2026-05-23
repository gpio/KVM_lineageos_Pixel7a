#!/data/data/com.termux/files/usr/bin/bash
# Termux:Boot — rend /dev/kvm accessible à Termux.
# Nécessite les permissions root (Magisk ou su).
# Placer dans ~/.termux/boot/kvm_fix.sh

su -c "chmod 666 /dev/kvm"
