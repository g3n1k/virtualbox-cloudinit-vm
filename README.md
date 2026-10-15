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
- `NET_MODE` — default: `bridged`. Pilihan: `bridged` atau `nat`.
- `SSH_HOST_PORT` — default: `2222`. Port SSH:
  - `bridged`: sshd di VM diatur untuk mendengarkan pada port ini, koneksi langsung ke `IP_VM:SSH_HOST_PORT`.
  - `nat`: port host yang di-forward ke port SSH (22) guest, koneksi via `localhost:SSH_HOST_PORT`.
  Gunakan nilai berbeda untuk setiap VM jika membuat banyak VM dengan mode NAT.
- `IP_ADDRESS` — default: `192.168.68.201`
- `IP_GATEWAY` — default: `192.168.68.1`
- `DNS_SERVERS` — default: `192.168.100.1,192.168.68.1,1.1.1.1`

### Mode jaringan (bridged vs nat)

- **`bridged`** (default): VM dihubungkan langsung ke jaringan fisik lewat adapter host. IP statis ditetapkan via `IP_ADDRESS` / `IP_GATEWAY` / `DNS_SERVERS`, dan VM bisa diakses langsung dari jaringan yang sama.
- **`nat`**: VM di belakang NAT VirtualBox (biasanya `10.0.2.x`) dan mendapatkan IP otomatis lewat DHCP. Akses SSH dari host dilakukan melalui port forwarding (`localhost:<SSH_HOST_PORT>`):

  ```bash
  ssh -p 2222 indra@localhost
  ```

  ```bash
  sh create-vm.sh VM_NAME=vm1 NET_MODE=nat SSH_HOST_PORT=2222
  ```

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
- `render.py` menerima argumen berformat `KEY=VALUE` (semua opsional, dengan nilai default):

  ```bash
  python3 render.py \
    name=indra \
    password=pass \
    hostname=vm1 \
    ip_address=192.168.68.202 \
    ip_gateway=192.168.68.1 \
    dns_servers="192.168.100.1, 192.168.68.1, 1.1.1.1" \
    net_mode=bridged
  ```

  Kunci yang didukung: `name`, `password`, `hostname`, `ip_address`, `ip_gateway`, `dns_servers`, `net_mode`, `ssh_host_port`.
  Alias: `user`/`nama`/`username` → `name`, `pass`/`katasandi` → `password`, `host` → `hostname`, `ip` → `ip_address`, `ip_gateway` → gateway, `dns` → `dns_servers`.

- `network-config.template.yml` menyesuaikan `dhcp4` dan blok IP statis secara otomatis berdasarkan `net_mode`.
- sesuaikan isi template dengan lingkungan yang ada