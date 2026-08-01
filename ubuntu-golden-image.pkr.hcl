packer {
    required_plugins {
        azure = {
            version = ">= 1.0.0"
            source  = "github.com/hashicorp/azure" 
        }
        ansible = {
            version = ">= 1.1.0"
            source  = "github.com/hashicorp/ansible"
        }
    }
}

variable "resource_group" {
    type    = string
    default = "rg-golden-images"
}

variable "location" {
    type    = string
    default = "Southeast Asia"
}

source "azure-arm" "ubuntu_base" {
    use_azure_cli_auth = true # will use github actions OIDC

    os_type         = "Linux"
    image_publisher = "Canonical"
    image_offer     = "0001-com-ubuntu-server-jammy"
    image_sku       = "22_04-lts"

    managed_image_resource_group_name = var.resource_group
    managed_image_name = "golden-ubuntu-2204-${formatdate("YYYYMMDDhhmmss", timestamp())}"
    
    location = var.location
    vm_size  = "Standard_B2s"
}

build {
  sources = ["source.azure-arm.ubuntu_base"]

  # Step 1: Run Ansible Playbook on the provisioned Azure VM
  provisioner "ansible" {
    playbook_file = "./ansible/setup.yml"
    user          = "packer"
  }

  # Step 2: Azure Generalization / Deprovisioning (MUST for Azure Golden Images)
  provisioner "shell" {
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
  }
}