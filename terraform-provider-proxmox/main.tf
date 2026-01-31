terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
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
  type      = string
  sensitive = true
}
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  pm_tls_insecure = true
  pm_debug        = true
}
# --- Master Node ---
resource "proxmox_vm_qemu" "k3s-master" {
  count       = 1
  name        = "k3s-master"
  target_node = "local"
  vmid        = 201
  clone       = "debian12-cloudinit"
  full_clone  = false

  # ใช้สเปคมาตรฐาน
  cpu {
    cores   = 2
    sockets = 1
  }

  memory = 4096
  scsihw = "virtio-scsi-single"
  boot   = "order=scsi0"

  # ปิด Agent ก่อน (เผื่อใน Template ยังไม่ได้ลง จะได้ไม่ค้างรอ Agent)
  agent = 1

  serial {
    id   = 0
    type = "socket"
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "st500"
          # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
          size = "40G"
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide0 {
        cloudinit {
          storage = "st500"
        }
      }
    }
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-Init configuration
  os_type    = "cloud-init"
  cicustom   = "vendor=local:snippets/master.yaml" # /var/lib/vz/snippets
  ciupgrade  = true
  nameserver = "1.1.1.1 8.8.8.8"
  ipconfig0  = "ip=192.168.1.12/24,gw=192.168.1.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = "root"
  cipassword = "Enter123!"
  sshkeys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMp/LI+g4xuUMSFGXdotnUgZvuMtzjL7PDQDFrCW3W27 root@traipoap-desktop"
}

# --- Worker Node ---
resource "proxmox_vm_qemu" "k3s-worker" {
  count       = 1
  name        = "k3s-worker-01"
  target_node = "local"
  vmid        = 202
  clone       = "debian12-cloudinit"
  full_clone  = false

  # ใช้สเปคมาตรฐาน
  cpu {
    cores   = 2
    sockets = 1
  }

  memory = 8192
  scsihw = "virtio-scsi-single"
  boot   = "order=scsi0"

  # ปิด Agent ก่อน (เผื่อใน Template ยังไม่ได้ลง จะได้ไม่ค้างรอ Agent)
  agent = 1

  serial {
    id   = 0
    type = "socket"
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "st500"
          # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
          size = "40G"
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide0 {
        cloudinit {
          storage = "st500"
        }
      }
    }
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-Init configuration
  os_type    = "cloud-init"
  cicustom   = "vendor=local:snippets/worker.yaml" # /var/lib/vz/snippets
  ciupgrade  = true
  nameserver = "1.1.1.1 8.8.8.8"
  ipconfig0  = "ip=192.168.1.22/24,gw=192.168.1.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = "root"
  cipassword = "Enter123!"
  sshkeys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMp/LI+g4xuUMSFGXdotnUgZvuMtzjL7PDQDFrCW3W27 root@traipoap-desktop"
}
