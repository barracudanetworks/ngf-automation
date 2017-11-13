resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-VNET"
  address_space       = ["${var.vnet}"]
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-SUBNET-NGF"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_ngf}"
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.prefix}-SUBNET-FRONTEND"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_frontend}"
  route_table_id       = "${azurerm_route_table.frontendroute.id}"
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.prefix}-SUBNET-BACKEND"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_backend}"
  route_table_id       = "${azurerm_route_table.backendroute.id}"
}

resource "azurerm_route_table" "frontendroute" {
  name                = "${var.prefix}-RT-FRONTEND"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  route {
    name                = "${var.prefix}-BackendToInternet"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_ipaddress}"
  }

  route {
    name                = "${var.prefix}-FrontendToBackend"
    address_prefix          = "172.16.138.0/24"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_ipaddress}"
  }
}

resource "azurerm_route_table" "backendroute" {
  name                = "${var.prefix}-RT-BACKEND"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  route {
    name                = "${var.prefix}-BackendToInternet"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_ipaddress}"
  }
  route {
    name                = "${var.prefix}-BackendToFrontend"
    address_prefix          = "172.16.137.0/24"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_ipaddress}"
  }
}

resource "azurerm_public_ip" "ngfpip" {
  name                         = "${var.prefix}-VM-NGF-PIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "ngfifc" {
  name                = "${var.prefix}-VM-NGF-IFC"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  enable_ip_forwarding  = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.ngf_ipaddress}"
    public_ip_address_id          = "${azurerm_public_ip.ngfpip.id}"
  }
}

resource "azurerm_virtual_machine" "ngfvm" {
  name                  = "${var.prefix}-VM-NGF"
  location              = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids = ["${azurerm_network_interface.ngfifc.id}"]
  vm_size               = "${var.vmsize}"

  storage_image_reference {
    publisher = "barracudanetworks"
    offer     = "barracuda-ng-firewall"
    sku       = "${var.imagesku}"
    version   = "latest"
  }

  plan {
    publisher = "barracudanetworks"
    product   = "barracuda-ng-firewall"
    name      = "byol"
  }

  storage_os_disk {
    name              = "${var.prefix}-VM-NGF-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-VM-NGF"
    admin_username = "azureuser"
    admin_password = "${var.password}"
    custom_data = "${base64encode("#!/bin/bash\n\nNGFIP=${var.ngf_ipaddress}\n\nNGFNM=${var.ngf_subnetmask}\n\nNGFGW=${var.ngf_defaultgateway}\n\n${file("${path.module}/scripts/provisionngf.sh")}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"
  }
}
