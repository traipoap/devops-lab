provider "proxmox" {
  endpoint = "https://proxmox.codezap.win"
  username = "root@pam"
  password = "t,xZzEe{l'xE,s12S@J'Tf]^(3%+Zr#ob+4O+ScHw2gbYesw%_"
  insecure = true

  ssh {
    agent    = true
    username = "root"
    password = "t,xZzEe{l'xE,s12S@J'Tf]^(3%+Zr#ob+4O+ScHw2gbYesw%_"
  }
}
