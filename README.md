# ubuntu-cloud

Template otomatis untuk membuat VM [**Ubuntu 24.04 Server (Noble)**](https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova) di **VirtualBox** menggunakan **cloud-init** (seed ISO).

Project ini merender template cloud-init (`user-data`, `meta-data`, `network-config`) lalu membuat VM dari file OVA yang sudah ada, termasuk memasang `seed.iso` sebagai sumber cloud-init.

## Tujuan

- Mempercepat provisioning VM Ubuntu cloud image di VirtualBox.
- Membakukan konfigurasi user SSH, network statis, package dasar, dan perintah cloud-init.
- Menyediakan nilai default yang dapat di-override lewat argument `KEY=VALUE` (Makefile / script).
- Menghindari konfigurasi manual berulang untuk setiap VM.

## File yang harus ada

### Input template

- `user-data.template.yml` — template user cloud-init (user, password, SSH key, packages, `runcmd`).
- `meta-data.template.yml` — template metadata VM (instance-id / local-hostname).
- `network-config.template.yml` — template konfigurasi jaringan netplan.
- `noble-server-cloudimg-amd64.ova` — image Ubuntu 24.04 cloud yang di-import oleh VirtualBox.
- `render.py` — renderer Jinja2 untuk menghasilkan `user-data`, `meta-data`, dan `network-config`.
- `create-vm.sh` — skrip end-to-end: render template, buat `seed.iso`, import OVA, pasang ISO, jalankan VM.

### File yang dihasilkan

- `user-data` — hasil render dari `user-data.template.yml`.
- `meta-data` — hasil render dari `meta-data.template.yml`.
- `network-config` — hasil render dari `network-config.template.yml`.
- `seed.iso` — ISO `nocloud`/`cloud-init` yang akan dipasang ke VM.

## Prasyarat

Install terlebih dahulu:

- VirtualBox (`VBoxManage`).
- `cloud-localds` (paket `cloud-image-utils` / `cloud-utils`).
- Python 3.
- Jinja2 Python (`python3 -c "import jinja2"`).

## Cara pakai

### 1. Buat VM dari script

```bash
sh create-vm.sh VM_NAME=vm1
```

Contoh dengan parameter custom:

```bash
sh create-vm.sh VM_NAME=vm1 USER=indra PASS=pass IP_ADDRESS=192.168.68.202 RAM_MB=2048 CPU_COUNT=2 NET_ADAPTER=wlo1
```

Parameter yang didukung:

- `VM_NAME` (wajib)
- `USER` — default: `ub`
- `PASS` — default: `P@ssw0rd`
- `RAM_MB` — default: `1024`
- `CPU_COUNT` — default: `2`
- `NET_ADAPTER` — default: `wlo1`
- `IP_ADDRESS` — default: `192.168.68.201`
- `IP_GATEWAY` — default: `192.168.68.1`
- `DNS_SERVERS` — default: `192.168.100.1,192.168.68.1,1.1.1.1`

### 3. Akses SSH

IP VM mengikuti `network-config`, secara default `192.168.68.201`.

```bash
ssh indra@192.168.68.201
```

Karena default public key sudah terpasang di `user-data.template.yml`, SSH client host Anda dapat login otomatis memakai private key default di `~/.ssh` yang cocok.

Untuk pakai key tertentu:

```bash
ssh -i ~/.ssh/your_key -o IdentitiesOnly=yes indra@192.168.68.201
```

Untuk login password (jika diaktifkan), set `PubkeyAuthentication=no` atau gunakan:

```bash
sshpass -p 'pass' ssh indra@192.168.68.201
```

## Catatan penting

- Semua VM memakai IP statis yang sama (`192.168.68.201`) secara default. Untuk VM kedua/ketiga, set `IP_ADDRESS` berbeda (mis. `.202`, `.203`) agar tidak bentrok.
- Template `user-data` menambahkan public SSH key default (`g3n1k@pop-os`). Ganti dengan public key Anda jika diperlukan.
- `create-vm.sh` meng-import file OVA yang ada di folder project.
- Folder VM dibuat di parent project: `../<VM_NAME>/`.
- `render.py` mendukung:
  - 3 argumen minimal (default network) bagi penggunaan `make build`.
  - hingga 6 argumen (user, password, hostname, IP, gateway, DNS) bagi `create-vm.sh`.
- sesuaikan isi template dengan lingkungan yang ada