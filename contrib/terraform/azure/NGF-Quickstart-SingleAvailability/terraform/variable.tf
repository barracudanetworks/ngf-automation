variable "password" { 
    description = "The password for the Barracuda VM to use"
}

variable "tenant_id" { 
    description = "The Azure RM tenant ID to use"
}

variable "subscription_id" { 
    description = "The Azure RM subscription ID to use"
}

variable "client_id" { 
    description = "The Azure RM client ID to use"
}

variable "client_secret" { 
    description = "The Azure RM client secret to use"
}

variable "location" {
    description = "The name of the resource group in which to create the virtual network."
    default = "West Europe"
}

variable "prefix" {
    description = "The shortened abbreviation to represent your resource group that will go on the front of some resources."
    default     = "JVH16"
}

variable "imagesku" {
    description = "SKU Hourly (PAYG) or Bring your own license (BYOL)"
    default     = "byol"
}

variable "vmsize" {
    description = "Size of the VMs to be created"
    default     = "Standard_DS1_v2"
}

variable "vnet" {
    description = "Network range of the VNET (e.g. 172.16.136.0/22)"
    default = "172.16.136.0/22"
}

variable "subnet_ngf" {
    description = "Network range of the Subnet containing the NextGen Firewall (e.g. 172.16.136.0/24)"
    default = "172.16.136.0/24"
}

variable "subnet_frontend" {
    description = "Network range of the frontend subnet (e.g. 172.16.137.0/24)"
    default = "172.16.137.0/24"
}

variable "subnet_backend" {
    description = "Network range of the backend subnet (e.g. 172.16.138.0/24)"
    default = "172.16.138.0/24"
}

variable "ngf_ipaddress" {
    description = ""
    default = "172.16.136.10"
}

variable "ngf_subnetmask" {
    description = "Subnetmask of the internal IP address of the NGF (e.g. 24)"
    default = "24"
}

variable "ngf_defaultgateway" {
    description = "Default gateway of the NGF network. This is always the first IP in the Azure subnet where the NGF is located. (e.g. 172.16.136.1)"
    default = "172.16.136.1"
}
