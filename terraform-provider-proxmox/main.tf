terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }

  cloud {
    organization = "codezap"
    workspaces {
      name = "proxmox"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}
variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}
variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}
provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  pm_tls_insecure = true
  pm_debug = true
}
# --- Master Node ---
resource "proxmox_vm_qemu" "k3s-master" {
  count       = 1
  name        = "k3s-master"
  target_node = "local"
  vmid        = 201
  clone       = "ubuntu-24-template"
  full_clone  = false

  # ใช้สเปคมาตรฐาน
  cores   = 2
  memory  = 4096
  scsihw  = "virtio-scsi-pci" # เปลี่ยนจาก virtio-scsi-single มาเป็นตัวนี้ชั่วคราว

  # ตั้งค่า Boot ให้ชัวร์
  boot    = "order=scsi0"

  # ปิด Agent ก่อน (เผื่อใน Template ยังไม่ได้ลง จะได้ไม่ค้างรอ Agent)
  agent   = 0

  # ใช้ VGA มาตรฐานเพื่อให้ดู NoVNC ได้
  vga {
    type = "std"
  }

  disk {
    slot    = "scsi0"
    size    = "32G"
    type    = "disk"
    storage = "st500"
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # ใส่ Cloud-init พื้นฐาน
  os_type     = "cloud-init"
  nameserver  = "8.8.8.8 1.1.1.1"
  ipconfig0   = "ip=192.168.1.102/24,gw=192.168.1.1"
  ciuser      = "admin"
  cipassword  = "admin"
}

# --- Worker Node ---
resource "proxmox_vm_qemu" "k3s-worker" {
  count       = 0
  name        = "k3s-worker-01"
  target_node = "local"
  vmid        = 202
  clone       = "ubuntu-24-template"
  full_clone  = false

  # ใช้สเปคมาตรฐาน
  cores   = 2
  memory  = 4096
  scsihw  = "virtio-scsi-pci" # เปลี่ยนจาก virtio-scsi-single มาเป็นตัวนี้ชั่วคราว

  # ตั้งค่า Boot ให้ชัวร์
  boot    = "order=scsi0"

  # ปิด Agent ก่อน (เผื่อใน Template ยังไม่ได้ลง จะได้ไม่ค้างรอ Agent)
  agent   = 0

  # ใช้ VGA มาตรฐานเพื่อให้ดู NoVNC ได้
  vga {
    type = "std"
  }

  disk {
    slot    = "scsi0"
    size    = "40G" # เพิ่มพื้นที่ disk สำหรับเก็บ Docker Images/Logs
    type    = "disk"
    storage = "st500"
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-Init
  os_type     = "cloud-init"
  nameserver  = "8.8.8.8 1.1.1.1"
  ipconfig0   = "ip=192.168.1.102/24,gw=192.168.1.1"
  ciuser      = "admin"
  cipassword  = "admin"
}
