resource "azurerm_ip_group" "tm_ipgroup" {
  name                = var.ip_group_name
  location            = azurerm_resource_group.tm_ipgroup.location
  resource_group_name = azurerm_resource_group.tm_ipgroup.name

  cidrs = []

  tags = var.tags

  lifecycle {
    ignore_changes = [
      cidrs, # Maintained by the Logic App
    ]
  }
}

resource "azurerm_logic_app_workflow" "tm_ipgroup" {
  name                = var.logic_app_name
  location            = azurerm_resource_group.tm_ipgroup.location
  resource_group_name = azurerm_resource_group.tm_ipgroup.name

  workflow_parameters = {
    IpGroupResourceId = jsonencode({ type = "String" })
  }
  parameters = {
    IpGroupResourceId = azurerm_ip_group.tm_ipgroup.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "logic_app_ip_group" {
  scope                = azurerm_ip_group.tm_ipgroup.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_logic_app_workflow.tm_ipgroup.identity[0].principal_id
}

resource "azurerm_resource_group" "tm_ipgroup" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
