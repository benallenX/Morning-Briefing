resource "azurerm_public_ip" "web_ip" {
  name                = "pip-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "web_nic" {
  name                = "nic-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_ip.id
  }
}

resource "random_password" "vm_admin" {
  length           = 20
  special          = true
  override_special = "!@#$%^&*()-_=+"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_windows_virtual_machine" "web_vm" {
  name                = "vm-web-01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"

  admin_username = "azureuser"
  admin_password = random_password.vm_admin.result

  network_interface_ids = [
    azurerm_network_interface.web_nic.id
  ]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  tags = var.tags
}

output "vm_admin_username" {
  value = azurerm_windows_virtual_machine.web_vm.admin_username
}

output "vm_admin_password" {
  value     = random_password.vm_admin.result
  sensitive = true
}

output "vm_public_ip" {
  value = azurerm_public_ip.web_ip.ip_address
}
