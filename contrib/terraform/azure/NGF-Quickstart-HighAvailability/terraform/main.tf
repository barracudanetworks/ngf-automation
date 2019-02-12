resource "azurerm_resource_group" "resourcegroupvnet" {
  name     = "${var.prefix}-RG-VNET"
  location = "${var.location}"
}

resource "azurerm_resource_group" "resourcegroupngf" {
  name     = "${var.prefix}-RG-NGF"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-VNET"
  address_space       = ["${var.vnet}"]
  location            = "${azurerm_resource_group.resourcegroupvnet.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-SUBNET-NGF"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_ngf}"
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.prefix}-SUBNET-FRONTEND"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_frontend}"
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.prefix}-SUBNET-BACKEND"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_backend}"
}

resource "azurerm_route_table" "frontendroute" {
  name                = "${var.prefix}-RT-FRONTEND"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"

  route {
    name                = "${var.prefix}-BackendToInternet"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_a_ipaddress}"
  }

  route {
    name                = "${var.prefix}-FrontendToBackend"
    address_prefix          = "172.16.138.0/24"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_a_ipaddress}"
  }
}

resource "azurerm_route_table" "backendroute" {
  name                = "${var.prefix}-RT-BACKEND"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"

  route {
    name                = "${var.prefix}-BackendToInternet"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_a_ipaddress}"
  }
  route {
    name                = "${var.prefix}-BackendToFrontend"
    address_prefix          = "172.16.137.0/24"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "${var.ngf_a_ipaddress}"
  }
}

resource "azurerm_public_ip" "ngfpip" {
  name                         = "${var.prefix}-VM-NGF-PIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupngf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "ngfifc" {
  name                = "${var.prefix}-VM-NGF-IFC"
  location            = "${azurerm_resource_group.resourcegroupngf.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupngf.name}"
  enable_ip_forwarding  = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.ngf_a_ipaddress}"
    public_ip_address_id          = "${azurerm_public_ip.ngfpip.id}"
  }
}

resource "azurerm_availability_set" "ngfavset" {
  name                = "${var.prefix}-NGF-AVSET"
  location            = "${var.location}"
  managed             = true
  resource_group_name = "${azurerm_resource_group.resourcegroupngf.name}"
}

resource "azurerm_public_ip" "ngflbpip" {
  name                         = "${var.prefix}-LB-NGF-PIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupngf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "ngfifca" {
  name                  = "${var.prefix}-VM-NGF-A-IFC"
  location              = "${azurerm_resource_group.resourcegroupngf.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupngf.name}"
  enable_ip_forwarding  = true

  ip_configuration {
    name                                    = "interface1"
    subnet_id                               = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation           = "static"
    private_ip_address                      = "${var.ngf_a_ipaddress}"
    public_ip_address_id                    = "${azurerm_public_ip.ngfpipa.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.ngflbbackend.id}"]
  }
}

resource "azurerm_network_interface" "ngfifcb" {
  name                  = "${var.prefix}-VM-NGF-B-IFC"
  location              = "${azurerm_resource_group.resourcegroupngf.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupngf.name}"
  enable_ip_forwarding  = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.ngf_b_ipaddress}"
    public_ip_address_id          = "${azurerm_public_ip.ngfpipb.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.ngflbbackend.id}"]
  }
}
resource "azurerm_lb" "ngflb" {
  name                = "${var.prefix}-LB-NGF"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupngf.name}"

  frontend_ip_configuration {
    name                 = "${var.prefix}-LB-NGF-PIP"
    public_ip_address_id = "${azurerm_public_ip.ngflbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "ngflbbackend" {
  resource_group_name = "${azurerm_resource_group.resourcegroupngf.name}"
  loadbalancer_id     = "${azurerm_lb.ngflb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "ngflbprobe" {
  resource_group_name = "${azurerm_resource_group.resourcegroupngf.name}"
  loadbalancer_id     = "${azurerm_lb.ngflb.id}"
  name                = "TINA-TCP-PROBE"
  port                = 691
}

resource "azurerm_lb_rule" "ngflbruletinatcp" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupngf.name}"
  loadbalancer_id                = "${azurerm_lb.ngflb.id}"
  name                           = "TINA-TCP"
  protocol                       = "Tcp"
  frontend_port                  = 691
  backend_port                   = 691
  frontend_ip_configuration_name = "${var.prefix}-LB-NGF-PIP"
  probe_id                       = "${azurerm_lb_probe.ngflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.ngflbbackend.id}"
}

resource "azurerm_lb_rule" "ngflbruletinaudp" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupngf.name}"
  loadbalancer_id                = "${azurerm_lb.ngflb.id}"
  name                           = "TINA-UDP"
  protocol                       = "Udp"
  frontend_port                  = 691
  backend_port                   = 691
  frontend_ip_configuration_name = "${var.prefix}-LB-NGF-PIP"
  probe_id                       = "${azurerm_lb_probe.ngflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.ngflbbackend.id}"
}

resource "azurerm_lb_rule" "ngflbruleipsecike" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupngf.name}"
  loadbalancer_id                = "${azurerm_lb.ngflb.id}"
  name                           = "IPSEC-IKE"
  protocol                       = "Udp"
  frontend_port                  = 500
  backend_port                   = 500
  frontend_ip_configuration_name = "${var.prefix}-LB-NGF-PIP"
  probe_id                       = "${azurerm_lb_probe.ngflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.ngflbbackend.id}"
}

resource "azurerm_lb_rule" "ngflbruleipsecnatt" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupngf.name}"
  loadbalancer_id                = "${azurerm_lb.ngflb.id}"
  name                           = "IPSEC-NATT"
  protocol                       = "Udp"
  frontend_port                  = 4500
  backend_port                   = 4500
  frontend_ip_configuration_name = "${var.prefix}-LB-NGF-PIP"
  probe_id                       = "${azurerm_lb_probe.ngflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.ngflbbackend.id}"
}

resource "azurerm_public_ip" "ngfpipa" {
  name                         = "${var.prefix}-VM-NGF-A-PIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupngf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_public_ip" "ngfpipb" {
  name                         = "${var.prefix}-VM-NGF-B-PIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupngf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_virtual_machine" "ngfvma" {
  name                  = "${var.prefix}-VM-NGF-A"
  location              = "${azurerm_resource_group.resourcegroupngf.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupngf.name}"
  network_interface_ids = ["${azurerm_network_interface.ngfifca.id}"]
  vm_size               = "${var.ngf_vmsize}"
  availability_set_id   = "${azurerm_availability_set.ngfavset.id}"

  storage_image_reference {
    publisher = "barracudanetworks"
    offer     = "barracuda-ng-firewall"
    sku       = "${var.ngf_imagesku}"
    version   = "latest"
  }

  plan {
    publisher = "barracudanetworks"
    product   = "barracuda-ng-firewall"
    name      = "${var.ngf_imagesku}"
  }

  storage_os_disk {
    name              = "${var.prefix}-VM-NGF-A-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-VM-NGF-A"
    admin_username = "azureuser"
    admin_password = "${var.password}"
    custom_data = "${base64encode("#!/bin/bash\n\nNGFIP=${var.ngf_a_ipaddress}\n\nNGFNM=${var.ngf_subnetmask}\n\nNGFGW=${var.ngf_defaultgateway}\n\n${file("${path.module}/scripts/provisionngf.sh")}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"
  }
}

resource "azurerm_virtual_machine" "ngfvmb" {
  name                  = "${var.prefix}-VM-NGF-B"
  location              = "${azurerm_resource_group.resourcegroupngf.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupngf.name}"
  network_interface_ids = ["${azurerm_network_interface.ngfifcb.id}"]
  vm_size               = "${var.ngf_vmsize}"
  availability_set_id   = "${azurerm_availability_set.ngfavset.id}"

  storage_image_reference {
    publisher = "barracudanetworks"
    offer     = "barracuda-ng-firewall"
    sku       = "${var.ngf_imagesku}"
    version   = "latest"
  }

  plan {
    publisher = "barracudanetworks"
    product   = "barracuda-ng-firewall"
    name      = "${var.ngf_vmsize}"
  }

  storage_os_disk {
    name              = "${var.prefix}-VM-NGF-B-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-VM-NGF-B"
    admin_username = "azureuser"
    admin_password = "${var.password}"
    custom_data = "${base64encode("#!/bin/bash\n\nNGFIP=${var.ngf_b_ipaddress}\n\nNGFNM=${var.ngf_subnetmask}\n\nNGFGW=${var.ngf_defaultgateway}\n\n${file("${path.module}/scripts/provisionngf.sh")}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"
  }
}