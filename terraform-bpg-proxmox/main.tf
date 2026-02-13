data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

# สร้างไฟล์ Cloud-init แยกออกมาเพื่อให้จัดการง่าย
resource "proxmox_virtual_environment_file" "k8s_master_cloud_config" {
  content_type = "snippets"
  datastore_id = "st500" # หรือที่ที่เก็บ snippets ของคุณ
  node_name    = "local"

  source_raw {
    data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - qemu-guest-agent
      - btop
      - fish
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg

    runcmd:
      - systemctl enable --now qemu-guest-agent
      - swapoff -a
      - sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
      - modprobe overlay
      - modprobe br_netfilter
      - printf "overlay\nbr_netfilter\n" > /etc/modules-load.d/k8s.conf
      - printf "net.bridge.bridge-nf-call-iptables  = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward                 = 1\n" > /etc/sysctl.d/k8s.conf
      - sysctl --system
      - apt update && apt install -y containerd
      - mkdir -p /etc/containerd
      - containerd config default > /etc/containerd/config.toml
      - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
      - systemctl restart containerd
      - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
      - apt update && apt install -y kubelet kubeadm kubectl
      - apt-mark hold kubelet kubeadm kubectl
      - |
        kubeadm init --pod-network-cidr=10.244.0.0/16 \
        --apiserver-advertise-address=192.168.1.12 \
        --token=abcdef.0123456789abcdef \
        --node-name k8s-master
      - mkdir -p /root/.kube
      - cp -i /etc/kubernetes/admin.conf /root/.kube/config
    EOF

    file_name = "k8s-master.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "k8s_master" {
  name      = "k8s-master"
  node_name = "local"
  vm_id     = 201

  clone {
    vm_id = 1000 # ID ของ Ubuntu Template
  }

  initialization {
    datastore_id = "st500"
    user_data_file_id = proxmox_virtual_environment_file.k8s_master_cloud_config.id

    ip_config {
      ipv4 {
        address = "192.168.1.12/24"
        gateway = "192.168.1.1"
      }
    }

    user_account {
      username = "root"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}
