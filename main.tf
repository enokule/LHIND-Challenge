#Create resource group "lhind-challenge"
resource "azurerm_resource_group" "lhind-challenge" {
   name     = "lhind-challenge"
   location = "norwayeast"
 }

# Create virtual network
 resource "azurerm_virtual_network" "myterraformnetwork" {
   name                = "myterraformnetwork"
   address_space       = ["10.0.0.0/16"]
   location            = azurerm_resource_group.lhind-challenge.location
   resource_group_name = azurerm_resource_group.lhind-challenge.name
 }


# Create subnet
 resource "azurerm_subnet" "myterraformsubnet" {
   name                 = "myterraformsubnet"
   resource_group_name  = azurerm_resource_group.lhind-challenge.name
   virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
   address_prefixes     = ["10.0.2.0/24"]
 }

# Create public IPs

 resource "azurerm_public_ip" "pip" {
   count                        = 3
   name                         = "myterraformpublicip${count.index}"
   location                     = azurerm_resource_group.lhind-challenge.location
   resource_group_name          = azurerm_resource_group.lhind-challenge.name
   allocation_method            = "Dynamic"
 }

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.lhind-challenge.location
  resource_group_name = azurerm_resource_group.lhind-challenge.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "32000"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
 resource "azurerm_network_interface" "myterraformnetworkinterface" {
   count               = 3
   name                = "network_interface${count.index}"
   location            = azurerm_resource_group.lhind-challenge.location
   resource_group_name = azurerm_resource_group.lhind-challenge.name

   ip_configuration {
     name                          = "ipConfiguration"
     subnet_id                     = azurerm_subnet.myterraformsubnet.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = element(azurerm_public_ip.pip.*.id, count.index)
   }
 }

#Associate security group to vm
resource "azurerm_network_interface_security_group_association" "example" {
  count                     = length(azurerm_network_interface.myterraformnetworkinterface.*.id)
  network_interface_id      = element(azurerm_network_interface.myterraformnetworkinterface.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.lhind-challenge.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.lhind-challenge.location
  resource_group_name      = azurerm_resource_group.lhind-challenge.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "eno_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


# Create nodes
resource "azurerm_linux_virtual_machine" "node" {
   count                 = 2
   name                  = "node${count.index}"
   location              = azurerm_resource_group.lhind-challenge.location

   resource_group_name   = azurerm_resource_group.lhind-challenge.name
   network_interface_ids = [element(azurerm_network_interface.myterraformnetworkinterface.*.id, count.index)]
   size               = "Standard_DS1_v2"

   source_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "18.04-LTS"
     version   = "latest"
   }

   os_disk {
    name                 = "myosdisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

   computer_name                   = "node${count.index}"
   admin_username                  = "eno"
   disable_password_authentication = true

   admin_ssh_key {
     username   = "eno"
     public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDj+slxFE+1F0CH7DpaxsTCTQUJW849e4Na/ObprmDQV0StUb3NkGWpEHZoHWgBRinCW6zlKnFyzRGbeqizd+PAxLDPAE1LfTThY6zym23RkNUQSwsw2Iaa5PnTBBa0YTZI58ev10LzfvJCSN5IXWpuFJroyad01nzH83RjZ9+B1w1pPCUDYQNq3Ww2cPvdOemvyU5U7MIB8XYfMJ5lJxijmlVGAA2k90qbhdq+kJZaxx6OwF8gKoKHrWuB96lgUmzlN/JjC6xPQp6835whJF32+BUnSuFdZfSVvBB5PLb8iGk/pDkRX50moM+Wqkxeoimp8Bnz8NtGGHV60ltxMBiLcH9H2xxP0k0I0L9KYisH2YfKWTZN3ugjp52M8OmII5ZMOAwdwMOdbZXQfDmC0EzTFwiyl1dM3+U5xxFPFDc3mDM2wqjpEUzKFCqEX27kiEyyR6wziVc/qWtDTntvXXuwTWt4zn0Q1OjjqaCaZSIZm4jRhfvSCUKsOYek9kC565k= root@eku-dev"
  }
   #Connect to Nodes
   provisioner "remote-exec" {
    inline = [
      "sudo apt update", "sudo apt install python3 -y", "echo Done!",
      "sudo mkdir -p /data/jenkins-volume",
      "sudo chown -R 1000:1000 /data/jenkins-volume"
    ]
    connection {
        type        = "ssh"
        user        = "eno"
        private_key = "${file(var.ssh_key_private)}"
        host        = self.public_ip_address
        timeout     = "1m"
     }
   }
}

resource "azurerm_linux_virtual_machine" "master" {
   name                  = "master"
   location              = azurerm_resource_group.lhind-challenge.location

   resource_group_name   = azurerm_resource_group.lhind-challenge.name
   network_interface_ids = [element(azurerm_network_interface.myterraformnetworkinterface.*.id, 2)]
   size               = "Standard_D2s_v3"

   source_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "18.04-LTS"
     version   = "latest"
   }

   os_disk {
    name                 = "myosdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

   computer_name                   = "master"
   admin_username                  = "eno"
   disable_password_authentication = true

   # Connect to Master
   provisioner "remote-exec" {
    inline = [
      "sudo apt update", "sudo apt install python3 -y", "echo Done!",
    ]
    connection {
        type        = "ssh"
        user        = "eno"
        private_key = "${file(var.ssh_key_private)}"
        host        = self.public_ip_address
        timeout     = "1m"
     }
   }

   admin_ssh_key {
     username   = "eno"
     public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDj+slxFE+1F0CH7DpaxsTCTQUJW849e4Na/ObprmDQV0StUb3NkGWpEHZoHWgBRinCW6zlKnFyzRGbeqizd+PAxLDPAE1LfTThY6zym23RkNUQSwsw2Iaa5PnTBBa0YTZI58ev10LzfvJCSN5IXWpuFJroyad01nzH83RjZ9+B1w1pPCUDYQNq3Ww2cPvdOemvyU5U7MIB8XYfMJ5lJxijmlVGAA2k90qbhdq+kJZaxx6OwF8gKoKHrWuB96lgUmzlN/JjC6xPQp6835whJF32+BUnSuFdZfSVvBB5PLb8iGk/pDkRX50moM+Wqkxeoimp8Bnz8NtGGHV60ltxMBiLcH9H2xxP0k0I0L9KYisH2YfKWTZN3ugjp52M8OmII5ZMOAwdwMOdbZXQfDmC0EzTFwiyl1dM3+U5xxFPFDc3mDM2wqjpEUzKFCqEX27kiEyyR6wziVc/qWtDTntvXXuwTWt4zn0Q1OjjqaCaZSIZm4jRhfvSCUKsOYek9kC565k= root@eku-dev"
  }
}

# Run ansible master.yml to Master
resource null_resource master_ansible {
  provisioner "local-exec" {
      command = "ansible-playbook -u eno -i '${azurerm_linux_virtual_machine.master.public_ip_address}', --private-key ${var.ssh_key_private} --become-method=sudo -b --become-user=root /root/lh-azure-cluster/ansible/master.yml"  
   }
}

# Run nodes.yml to Nodes
resource null_resource nodes_ansible {
 depends_on = [null_resource.master_ansible]
 count = 2
 provisioner "local-exec" {
    command = "ansible-playbook -u eno -i '${element(azurerm_linux_virtual_machine.node.*.public_ip_address, count.index)}', --private-key ${var.ssh_key_private} --become-method=sudo -b --become-user=root /root/lh-azure-cluster/ansible/nodes.yml"
  }
}

# Run helm.yml to Master
resource null_resource helm-jenkins-setup {
  depends_on = [null_resource.nodes_ansible]
  provisioner "local-exec" {
      command = "ansible-playbook -u eno -i '${azurerm_linux_virtual_machine.master.public_ip_address}', --private-key ${var.ssh_key_private} --become-method=sudo -b --become-user=root /root/lh-azure-cluster/ansible/helm.yml"  
   }
}

 

