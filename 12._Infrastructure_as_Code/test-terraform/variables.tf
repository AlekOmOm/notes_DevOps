variable "admin_ssh_key" {
  description = "The SSH key for the admin user"
  type        = string
  default     = "~/.ssh/keys/general/id_rsa.default.key.pub"
}

variable "admin_ssh_private_key" {
  description = "The private SSH key for the admin user"
  type        = string
  default     = "~/.ssh/keys/general/id_rsa.default.key"
}

variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
  default     = "main-vm"
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}
