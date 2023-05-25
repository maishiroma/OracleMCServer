## General Variables

variable "parent_compartment_id" {
  type        = string
  description = "The parent compartment to associate the deployment's compartment."
}

variable "project_name" {
  type        = string
  description = "The name of this project"
  default     = "mc-server"
}

## VPC Variables

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block to use for the VPC"
  default     = "10.0.0.0/16"
}

variable "pub_subnet_block" {
  type        = string
  description = "The CIDR block to use for the subnet"
  default     = "10.0.0.0/24"
}

variable "existing_pub_subnet" {
  type        = string
  description = "The ID of an existing public subnet. If left at \"\", will create a new VPN and associate this instance to it"
  default     = ""
}

variable "admin_ip_addresses" {
  type        = list(string)
  description = "List of IPs to allow SSH access"
  default     = []
}

variable "game_ip_addresses" {
  type        = list(string)
  description = "List of IPs to allow minecraft access"
  default     = []
}

## Instance Variables

variable "vm_shape" {
  type        = string
  description = "The shape of the VM. The default is part of the Always Free Tier"
  default     = "VM.Standard.A1.Flex"
}

variable "vm_specs" {
  type        = map(string)
  description = "The specs of the VM. Note that the default is part of the Always Free Tier"
  default = {
    memory = "6"
    cpus   = "2"
  }
}

variable "vm_image" {
  type        = string
  description = "The image ID that is used for the VM. Note that this default is for us-sanjose-1."
  default     = "ocid1.image.oc1.us-sanjose-1.aaaaaaaaxnfbpr6wcawvbgx56ls5v2lndcmp7q3e7guu3rkrwcfhecouxslq"
}

variable "availability_domain" {
  type        = string
  description = "The az to put the instance in. Note that this default is for us-sanjose-1"
  default     = "gEpX:US-SANJOSE-1-AD-1"
}

variable "pub_key" {
  type        = string
  description = "The public key to associate on the instance in order to provide SSH access"
}