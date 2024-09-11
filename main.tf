resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "public" {
  name                 = "${var.prefix}-public-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.public_subnet_cidr]
  depends_on           = [azurerm_virtual_network.this]

  delegation {
    name = "databricks-delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet" "private" {
  name                 = "${var.prefix}-private-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.private_subnet_cidr]
  depends_on           = [azurerm_virtual_network.this]

  delegation {
    name = "databricks-delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.prefix}-public-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_network_security_group" "private" {
  name                = "${var.prefix}-private-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
  depends_on                = [azurerm_network_security_group.public, azurerm_subnet.public]
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
  depends_on                = [azurerm_network_security_group.private, azurerm_subnet.private]
}

resource "azurerm_route_table" "public" {
  name                = "${var.prefix}-public-route-table"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_route_table" "private" {
  name                = "${var.prefix}-private-route-table"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public.id
  depends_on     = [azurerm_route_table.public, azurerm_subnet.public]
}

resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private.id
  depends_on     = [azurerm_route_table.private, azurerm_subnet.private]
}

resource "azurerm_storage_account" "databricks_storage" {
  name                     = "dbdgepoc${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on               = [azurerm_resource_group.this]
}

resource "random_string" "storage_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_databricks_workspace" "this" {
  name                = "${var.prefix}-workspace-dev"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "standard"

  custom_parameters {
    virtual_network_id                                   = azurerm_virtual_network.this.id
    public_subnet_name                                   = azurerm_subnet.public.name
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }
  depends_on = [
    azurerm_resource_group.this,
    azurerm_virtual_network.this,
    azurerm_subnet.public,
    azurerm_subnet.private,
    azurerm_subnet_network_security_group_association.public,
    azurerm_subnet_network_security_group_association.private
  ]
}