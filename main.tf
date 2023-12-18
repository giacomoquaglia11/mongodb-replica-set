locals {
  vnet_cidr = ["10.0.0.0/16"]
  subnet_cidr_1 = ["10.0.1.0/24"]
  vms_names = ["VM 01","VM 02","VM 03"]
  computer_name = "QuagliaVM"
  admin_username = "quagliagiacomo"
  admin_password = "QuagliaGiacomo01"
}
resource "azurerm_virtual_network" "vnet" {
  name = "${var.name_prefix}-vnet"
  address_space = local.vnet_cidr
  location = var.region
  resource_group_name = var.resource_group_name
}
resource "azurerm_subnet" "subnet" {
  name = "${var.name_prefix}-subnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = local.subnet_cidr_1
}
resource "azurerm_public_ip" "public_ip" {

  count = length(local.vms_names)

  name = "${var.name_prefix}-pip-${count.index + 1}"
  location = var.region
  resource_group_name = var.resource_group_name
  allocation_method = "Static"
  domain_name_label = "${var.name_prefix}-${count.index + 1}"
}
resource "azurerm_network_security_group" "nsg" {

  count = length(local.vms_names)

  name = "${var.name_prefix}-nsg-${count.index + 1}"
  location = var.region
  resource_group_name = var.resource_group_name

  security_rule {
    name = "AllowDelta"
    priority = 120
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefixes = concat(["*"], azurerm_public_ip.public_ip.*.ip_address)
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface" "nic" {
  
  count = length(local.vms_names)

  name = "${var.name_prefix}-nic-${count.index + 1}"
  location = var.region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "myNicConfiguration"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.public_ip.*.id, count.index)
  }
}
resource "azurerm_network_interface_security_group_association" "association" {  
  
  count = length(local.vms_names)
  
  network_interface_id = element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.nsg.*.id, count.index)
}
resource "azurerm_linux_virtual_machine" "mongo_db" {

  count = length(local.vms_names)

  name = "${var.name_prefix}-vm-${count.index + 1}"
  location = var.region
  resource_group_name = var.resource_group_name
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  size = "Standard_B2s"
  computer_name = "VM-${count.index + 1}"
  admin_username = local.admin_username
  admin_password = local.admin_password
  disable_password_authentication = false

  os_disk {
    name = "osdisk-${count.index + 1}"
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-focal"
    sku = "20_04-lts"
    version = "latest"
  }
}
resource "azurerm_managed_disk" "data_disk" {

  count = length(local.vms_names)

  name = "${var.name_prefix}-mongodb-disk-${count.index + 1}"
  location = var.region
  resource_group_name = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = 10
}
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attach" {

  count = length(local.vms_names)

  managed_disk_id = "${azurerm_managed_disk.data_disk[count.index].id}"
  virtual_machine_id = "${azurerm_linux_virtual_machine.mongo_db[count.index].id}"
  create_option = "Attach"
  lun = 1
  caching = "None"
}
output "vm_ips" {
  value = azurerm_public_ip.public_ip.*.ip_address
}
resource "null_resource" "mongodb_setup"{
  depends_on = [
    azurerm_linux_virtual_machine.mongo_db,
    azurerm_virtual_machine_data_disk_attachment.data_disk_attach
  ]
  count = length(local.vms_names)
  provisioner "file"{
    source = "backup.gz"
    destination = "/tmp/backup.gz"
    connection {
      type = "ssh"
      user = local.admin_username
      password = local.admin_password
      host = element(azurerm_public_ip.public_ip.*.ip_address, count.index)
      timeout = "10s"    
    }
  }
    provisioner "file"{
    source = "mongodb-keyfile"
    destination = "/tmp/mongodb-keyfile"
    connection {
      type = "ssh"
      user = local.admin_username
      password = local.admin_password
      host = element(azurerm_public_ip.public_ip.*.ip_address, count.index)
      timeout = "10s"    
    }
  }
  provisioner "file"{
    source = "mongodb-setup.sh"
    destination = "/tmp/mongodb-setup.sh"
    connection {
      type = "ssh"
      user = local.admin_username
      password = local.admin_password
      host = element(azurerm_public_ip.public_ip.*.ip_address, count.index)
    }
  }
  provisioner "remote-exec" {
      inline = [
      "chmod +x /tmp/mongodb-setup.sh",
      "sudo /tmp/mongodb-setup.sh",
    ]
    connection {
      type = "ssh"
      host = element(azurerm_public_ip.public_ip.*.ip_address, count.index)
      user = local.admin_username
      password = local.admin_password
    }
  }
}
resource "null_resource" "replica_set"{
  depends_on = [
    azurerm_linux_virtual_machine.mongo_db,
    azurerm_virtual_machine_data_disk_attachment.data_disk_attach,
    null_resource.mongodb_setup
  ]
  count = 1
  provisioner "file"{
    source = "replicaset.sh"
    destination = "/tmp/replicaset.sh"
    connection {
      type = "ssh"
      user = local.admin_username
      password = local.admin_password
      host = element(azurerm_public_ip.public_ip.*.ip_address, 0)
    }
  }
  provisioner "remote-exec" {
      inline = [
      "chmod +x /tmp/replicaset.sh",
      "sudo /tmp/replicaset.sh",
    ]
    connection {
      type = "ssh"
      host = element(azurerm_public_ip.public_ip.*.ip_address, 0)
      user = local.admin_username
      password = local.admin_password
    }
  }
}