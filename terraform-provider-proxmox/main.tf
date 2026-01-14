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
resource "proxmox_vm_qemu" "terraform-vm" {
  force_create= true
  vmid        = 105
  name        = "terraform-vm"
  target_node = "local"
  
  clone       = "ubuntu-24.04.2"
  full_clone  = false
  os_type     = "cloud-init"
  
  cores       = 1
  agent       = 0
  memory      = 1024
  scsihw      = "virtio-scsi-single"
  boot        = "order=scsi0"

  # Cloud-Init configuration
  nameserver = "1.1.1.1 8.8.8.8"
  ipconfig0  = "ip=192.168.1.10/24,gw=192.168.1.1"
  ciuser     = "traipoap"
  cipassword = "32110"
  sshkeys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/Pjg7YXZ8Yau9heCc4YWxFlzhThnI+IhUx2hLJRxYE Cloud-Init@Terraform"

  disk {
    slot    = "scsi0"
    size    = "32G"
    type    = "disk"
    storage = "st500"
    discard = false
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "e1000"
  }
}