#!/bin/bash

# --- 1. NILAI DEFAULT ---
USER="ub"
PASS="P@ssw0rd"
RAM_MB=1024
CPU_COUNT=2
NET_ADAPTER="wlo1"
NET_MODE="bridged"
VM_NAME=""
IP_ADDRESS="192.168.68.201"
IP_GATEWAY="192.168.68.1"
DNS_SERVERS="192.168.100.1,192.168.68.1,1.1.1.1"
SSH_HOST_PORT="2222"

# --- 2. PARSING ARGUMEN (KEY=VALUE) ---
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
        # user credentials
        USER)     USER=${VALUE} ;;
        PASS)     PASS=${VALUE} ;;

        # vm configuration
        VM_NAME)     VM_NAME=${VALUE} ;;
        RAM_MB)      RAM_MB=${VALUE} ;;
        CPU_COUNT)   CPU_COUNT=${VALUE} ;;
        NET_ADAPTER) NET_ADAPTER=${VALUE} ;;
        NET_MODE)  NET_MODE=${VALUE} ;;
        IP_ADDRESS)  IP_ADDRESS=${VALUE} ;;
        IP_GATEWAY)  IP_GATEWAY=${VALUE} ;;
        DNS_SERVERS) DNS_SERVERS=${VALUE} ;;
        SSH_HOST_PORT) SSH_HOST_PORT=${VALUE} ;;
        *)           ;;
    esac
done

# --- 3. VALIDASI INPUT WAJIB ---
if [ -z "$VM_NAME" ]; then
    echo "Error: Parameter 'VM_NAME' wajib diisi!"
    echo ""
    echo "Cara Penggunaan:"
    echo "  sh create-vm.sh VM_NAME=<nama_vm> [RAM_MB=<ukuran_ram>] [CPU_COUNT=<jumlah_cpu>] [NET_ADAPTER=<nama_adapter>] [NET_MODE=<bridged|nat>] [SSH_HOST_PORT=<port_host>]"
    echo ""
    echo "Contoh:"
    echo "  sh create-vm.sh VM_NAME=vm1"
    echo "  sh create-vm.sh VM_NAME=vm1 RAM_MB=4096 CPU_COUNT=4 NET_ADAPTER=wlan0"
    echo "  sh create-vm.sh VM_NAME=vm1 NET_MODE=nat"
    echo "  sh create-vm.sh VM_NAME=vm1 NET_MODE=nat SSH_HOST_PORT=2222"
    exit 1
fi

# --- RESOLVE BASE DIR (agar script bisa dijalankan dari folder mana pun) ---
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${BASE_DIR}"

# --- CREATE FILE SEED ISO ---
python3 render.py \
  name="${USER}" \
  password="${PASS}" \
  hostname="${VM_NAME}" \
  ip_address="${IP_ADDRESS}" \
  ip_gateway="${IP_GATEWAY}" \
  dns_servers="${DNS_SERVERS}" \
  net_mode="${NET_MODE}" \
  ssh_host_port="${SSH_HOST_PORT}"
cloud-localds seed.iso user-data meta-data --network-config network-config


# --- PATH FILE ASAL ---
BASE_DIR="${BASE_DIR}"
OVA_PATH="${BASE_DIR}/noble-server-cloudimg-amd64.ova"
SEED_ISO="${BASE_DIR}/seed.iso"

# --- TARGET FOLDER BARU (Di atas folder seed.iso) ---
TARGET_DIR="${BASE_DIR}/../${VM_NAME}"

# Cek apakah OVA ada
if [ ! -f "$OVA_PATH" ]; then
    echo "Error: File OVA tidak ditemukan di: $OVA_PATH"
    exit 1
fi

echo "==> Parameter yang digunakan:"
echo "    - USER       : $USER"
echo "    - PASS       : ****"
echo "    - VM Name    : $VM_NAME"
echo "    - RAM        : ${RAM_MB} MB"
echo "    - CPU        : $CPU_COUNT Core"
echo "    - Adapter    : $NET_ADAPTER"
echo "    - Net Mode   : $NET_MODE"
echo "    - SSH Port   : $SSH_HOST_PORT"
echo "    - Target Dir : $TARGET_DIR"

echo "==> 1. Mengimpor OVA ke folder: ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}"

VBoxManage import "${OVA_PATH}" \
  --vsys 0 --vmname "${VM_NAME}" \
  --vsys 0 --basefolder "${BASE_DIR}/.."

echo "==> 2. Mengatur RAM, CPU, dan Network..."
VBoxManage modifyvm "${VM_NAME}" --memory ${RAM_MB} --cpus ${CPU_COUNT} --vram 16
if [ "$NET_MODE" = "nat" ]; then
  VBoxManage modifyvm "${VM_NAME}" --nic1 nat
  VBoxManage modifyvm "${VM_NAME}" --natpf1 "ssh,tcp,,${SSH_HOST_PORT},,22"
else
  VBoxManage modifyvm "${VM_NAME}" --nic1 bridged --bridgeadapter1 "${NET_ADAPTER}"
fi

echo "==> 3. Memasang seed.iso..."
VBoxManage storageattach "${VM_NAME}" --storagectl "IDE" \
    --port 0 --device 0 --type dvddrive --medium "${SEED_ISO}" 2>/dev/null || \
VBoxManage storageattach "${VM_NAME}" --storagectl "SATA" \
    --port 1 --device 0 --type dvddrive --medium "${SEED_ISO}"

# echo "==> 4. Menjalankan VM secara headless..."
# VBoxManage startvm "${VM_NAME}" --type headless
echo "==> 4. Menjalankan VM GUI ..."
VBoxManage startvm "${VM_NAME}"

echo "==> Selesai! VM '${VM_NAME}' berhasil dibuat dan dijalankan."