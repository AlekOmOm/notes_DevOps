# 6. Terraform: Hands-On 💻

[<- Back: Terraform: Getting Started](./05-terraform-get-started.md) | [Next: Terraform: Limitations and Problems ->](./07-terraform-limitations-problems.md)

## Table of Contents

- [Working with Terraform Workspaces](#working-with-terraform-workspaces)
- [Creating a VM in Azure](#creating-a-vm-in-azure)
- [Working with Variables](#working-with-variables)
- [Creating Outputs](#creating-outputs)
- [Remote Provisioning](#remote-provisioning)

## Working with Terraform Workspaces

Terraform workspaces allow you to manage multiple states for the same configuration. They function similarly to branches in version control systems.

### Why Use Workspaces?

Workspaces are useful for:
- Managing different environments (dev, test, prod)
- Creating sandboxes for each developer
- Testing changes without affecting production

### Basic Workspace Commands

```bash
# Initialize the repository first
terraform init

# List available workspaces
terraform workspace list

# Create a new workspace
terraform workspace new dev
terraform workspace new prod

# Select a workspace
terraform workspace select dev

# Show the current workspace
terraform workspace show
```

### How Workspaces Work

- Each workspace maintains its own state
- State files are stored in the `terraform.tfstate.d` directory
- Each workspace has its own subdirectory in this directory
- The current workspace is tracked in the `.terraform/environment` file

## Creating a VM in Azure

Let's create a virtual machine in Azure using Terraform.

### Setup

1. Add Terraform templates to `.gitignore`:
   ```
   # Local .terraform directories
   **/.terraform/*

   # .tfstate files
   *.tfstate
   *.tfstate.*

   # Crash log files
   crash.log

   # Exclude all .tfvars files
   *.tfvars
   ```

2. Create a `main.tf` file with the Azure provider:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.83.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}
```

3. Initialize Terraform:
```bash
terraform init
terraform validate
terraform plan
```

### Complete VM Configuration

Add the following to your `main.tf`:

```hcl
resource "azurerm_resource_group" "terraform_class" {
  name     = "terraform_class-resources"
  location = "North Europe"
}

resource "azurerm_virtual_network" "terraform_class" {
  name                = "terraform_class-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform_class.location
  resource_group_name = azurerm_resource_group.terraform_class.name
}

resource "azurerm_subnet" "terraform_class" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraform_class.name
  virtual_network_name = azurerm_virtual_network.terraform_class.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "terraform_class" {
  name                = "terraform_class-publicip"
  location            = azurerm_resource_group.terraform_class.location
  resource_group_name = azurerm_resource_group.terraform_class.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "terraform_class" {
  name                = "terraform_class-nic"
  location            = azurerm_resource_group.terraform_class.location
  resource_group_name = azurerm_resource_group.terraform_class.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraform_class.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform_class.id
  }
}

resource "azurerm_linux_virtual_machine" "terraform_class" {
  name                = "main-vm"
  resource_group_name = azurerm_resource_group.terraform_class.name
  location            = azurerm_resource_group.terraform_class.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.terraform_class.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  disable_password_authentication = true
}

resource "azurerm_network_security_group" "terraform_class_nsg" {
  name                = "terraform_class-nsg"
  location            = azurerm_resource_group.terraform_class.location
  resource_group_name = azurerm_resource_group.terraform_class.name

  security_rule {
    name                       = "allow-8080"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_rule" "terraform_class_ssh_rule" {
  name                        = "SSH"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.terraform_class_nsg.name
  resource_group_name         = azurerm_resource_group.terraform_class.name
}
```

### Provisioning the VM

Now let's provision our defined infrastructure:

```bash
terraform fmt       # Format the configuration files
terraform validate  # Validate the configuration
terraform plan      # Preview the changes
terraform apply     # Apply the changes (confirm with 'yes')
```

After applying, verify that the VM has been created in the Azure portal.

## Creating Outputs

We can define outputs to display useful information after applying our configuration. Create a file named `outputs.tf`:

```hcl
output "public_ip_address" {
  value = azurerm_public_ip.terraform_class.ip_address
}

output "ssh_command" {
  value = "ssh ${one(azurerm_linux_virtual_machine.terraform_class.admin_ssh_key).username}@${azurerm_public_ip.terraform_class.ip_address}"
}
```

Run `terraform apply` again to see these outputs, or use:

```bash
terraform output
```

This will display the public IP address and a ready-to-use SSH command for connecting to your VM.

## Working with Variables

Variables make your Terraform configurations more flexible and reusable. Create a `variables.tf` file:

```hcl
variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
  default     = "main-vm"
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
  default     = "Standard_B4ms"
}
```

Now modify your `main.tf` to use these variables:

```hcl
resource "azurerm_linux_virtual_machine" "terraform_class" {
  name                = var.vm_name
  # ...other configuration...
  size                = var.vm_size
  # ...rest of configuration...
}
```

You can override these defaults by:
- Creating a `terraform.tfvars` file
- Passing variables on the command line: `terraform apply -var="vm_name=custom-vm"`
- Setting environment variables: `export TF_VAR_vm_name=custom-vm`

## Remote Provisioning

While Terraform is primarily designed for infrastructure provisioning, you can execute commands on your newly created VMs using provisioners.

Add a remote-exec provisioner to your VM resource:

```hcl
resource "azurerm_linux_virtual_machine" "terraform_class" {
  # ... existing configuration ...
  
  provisioner "remote-exec" {
    inline = split("\n", templatefile("${path.module}/inline_commands.sh", {}))

    connection {
      type        = "ssh"
      user        = "adminuser"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip_address
      timeout     = "2m"
    }
  }
}
```

Create an `inline_commands.sh` file with your shell commands:

```bash
echo "============================================================================================"
echo "Update packages"
echo "============================================================================================"
sudo apt-get update && sudo apt-get install -y software-properties-common
echo "============================================================================================"
echo "Install Docker and give user permission"
echo "============================================================================================"
sudo apt install -y docker.io
sudo usermod -aG docker $(whoami)
sudo systemctl restart docker
sudo apt install -y docker-compose
```

Note that:
- Provisioners are a last resort in Terraform
- Better alternatives include cloud-init, Packer, or configuration management tools
- Provisioners make it harder to maintain idempotency

### Cleaning Up

When you're done experimenting, destroy the resources:

```bash
terraform destroy
```

Verify in the Azure Portal that all resources have been removed.

---

[<- Back: Terraform: Getting Started](./05-terraform-get-started.md) | [Next: Terraform: Limitations and Problems ->](./07-terraform-limitations-problems.md)