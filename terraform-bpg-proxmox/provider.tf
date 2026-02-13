provider "proxmox" {
  endpoint = "https://proxmox.codezap.win"
  username = "root@pam!terraform"
  password = "beb0ec21-d6c6-49a6-a53d-b7afaf39a797"
  insecure = true

  ssh {
    agent = true
    username = "root"  # required when using api_token
    password = "Enter123!"
  }
}
