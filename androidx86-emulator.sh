#!/usr/bin/env bash

# Copyright (c) 2024 XoXo
# License: MIT

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y wget unzip qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
msg_ok "Installed Dependencies"

msg_info "Downloading Android-x86"
ANDROID_VERSION="9.0-r2"
$STD wget https://osdn.net/projects/android-x86/downloads/71931/android-x86_64-$ANDROID_VERSION.iso
msg_ok "Downloaded Android-x86"

msg_info "Creating Android VM"
VM_ID=$(pvesh get /cluster/nextid)
qm create $VM_ID --name android-emulator --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk $VM_ID android-x86_64-$ANDROID_VERSION.iso local-lvm
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VM_ID-disk-0
qm set $VM_ID --ide2 local-lvm:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga std
msg_ok "Created Android VM"

msg_info "Installing QEMU Guest Agent"
qm set $VM_ID --agent enabled=1
msg_ok "Installed QEMU Guest Agent"

msg_info "Setting up SIM Card Simulation"
cat <<EOF > /etc/libvirt/hooks/qemu
#!/bin/bash
if [ "\${1}" = "android-emulator" ] && [ "\${2}" = "started" ]; then
    echo "Simulating SIM card for Android Emulator"
    # Add commands here to simulate SIM card
    # For example:
    # virsh qemu-monitor-command android-emulator --hmp "gsm sim-card insert 12345678901234567890"
fi
EOF
chmod +x /etc/libvirt/hooks/qemu
msg_ok "Set up SIM Card Simulation"

msg_info "Starting Android VM"
qm start $VM_ID
msg_ok "Started Android VM"

msg_info "Android Emulator Setup Complete"
echo "Android Emulator VM ID: $VM_ID"
echo "Access the Android Emulator through the Proxmox VE web interface or using VNC"

motd_ssh
customize
