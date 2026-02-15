data "local_file" "ssh_public_key" {
  filename = "./id_ed25519.pub"
}

# 1. สร้างไฟล์ Cloud-config ไปเก็บไว้ที่ Proxmox Node (Storage: local)
resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "local"

  source_raw {
    data      = <<-EOF
    #cloud-config
    hostname: k3s-master
    timezone: Asia/Bangkok
    users:
      - default
      - name: traipoap
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
      - fish
      - btop
      - gpg
      - apt-transport-https
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done

      # --- ติดตั้ง K3s (ตัวอย่างของ Master) ---
      - curl -sfL https://get.k3s.io | sh -s - server \
              --node-ip=192.168.1.12 \
              --write-kubeconfig-mode 644 \
              --token=K10a82cb374b7a65b02e1695989a67bb8d36c301fb2b233737300329821f29d7f76::server:28e1756edd4e25302a8cc9f4191df9c4

      - curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
      - echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
      - apt-get update
      - apt-get install helm

    EOF
    file_name = "k3s-master.yaml"
  }
}

# 2. สร้าง VM โดยเรียกใช้ไฟล์ด้านบน
resource "proxmox_virtual_environment_vm" "k3s_master" {
  name      = "k3s-master"
  node_name = "local"
  vm_id     = 201

  clone {
    vm_id = 9000
    full  = false
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "st500"
    interface    = "scsi0"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
  }

  serial_device {}

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id

    ip_config {
      ipv4 {
        address = "192.168.1.12/24"
        gateway = "192.168.1.1"
      }
    }
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
      domain  = "."
    }
  }
}
