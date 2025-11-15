terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }

  cloud {
    organization = "codezap"
    workspaces {
      name = "proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.1.2:8006/api2/json"
  pm_api_token_id="root@pam!terraform"
  pm_api_token_secret="03f80266-0cce-48cf-a40f-6b266f9d154a"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "debian-13" {
  name        = "debian-13"
  target_node = "local"
  iso         = "debian-13.1.0-amd64-netinst.iso"
  cores       = 4
  memory      = 4096

  disk {
    size = "32G"
    type = "scsi"
    storage = "st500"
    discard = "on"
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
    firewall = false
    link_down = false
  }
}