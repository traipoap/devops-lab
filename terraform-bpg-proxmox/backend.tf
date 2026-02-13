terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.95.1-rc1"
    }
  }
  cloud {
    organization = "codezap"
    workspaces {
      name = "proxmox"
    }
  }
}
