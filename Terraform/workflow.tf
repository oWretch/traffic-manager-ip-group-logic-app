resource "azurerm_logic_app_trigger_recurrence" "every_day_2am" {
  name         = "At_2am_Every_Day"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id
  time_zone    = var.time_zone
  frequency    = "Day"
  interval     = 1
  schedule {
    at_these_hours = [2]
  }
}

#
# Branch 1 - Get Traffic Manager IPs
#
resource "azurerm_logic_app_action_http" "download_tm_ip_list" {
  name         = "Download_Traffic_Manager_IPs"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id
  method       = "GET"
  uri          = "https://azuretrafficmanagerdata.blob.core.windows.net/probes/azure/probe-ip-ranges.json"
}

resource "azurerm_logic_app_action_custom" "parse_tm_ip_list" {
  name         = "Parse_Traffic_Manager_IPs"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "ParseJson"
    runAfter = {
      (azurerm_logic_app_action_http.download_tm_ip_list.name) = ["Succeeded"]
    }
    inputs = {
      content = "@body('${azurerm_logic_app_action_http.download_tm_ip_list.name}')"
      schema = {
        type = "object"
        properties = {
          createDate = { type = "string" }
          ipv4_prefixes = {
            type = "array"
            items = {
              type = "object"
              properties = {
                ip_prefix = { type = "string" }
                service   = { type = "string" }
              }
              required = [
                "ip_prefix",
                "service",
              ]
            }
          }
          ipv6_prefixes = {
            type = "array"
            items = {
              type = "object"
              properties = {
                ip_prefix = { type = "string" }
                service   = { type = "string" }
              }
              required = [
                "ip_prefix",
                "service",
              ]
            }
          }
        }
      }
    }
  })
}

resource "azurerm_logic_app_action_custom" "intialize_tm_v4_ips" {
  name         = "Initialize_TrafficManagerV4IPs"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "InitializeVariable"
    runAfter = {
      (azurerm_logic_app_action_custom.parse_tm_ip_list.name) = ["Succeeded"]
    }
    inputs = {
      variables = [
        {
          name = "TrafficManagerV4IPs"
          type = "array"
        }
      ]
    }
  })
}

resource "azurerm_logic_app_action_custom" "for_each_tm_v4_ip" {
  name         = "For_Each_IPv4_Prefix"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "Foreach"
    runAfter = {
      (azurerm_logic_app_action_custom.intialize_tm_v4_ips.name) = ["Succeeded"]
    }
    foreach = "@body('${azurerm_logic_app_action_custom.parse_tm_ip_list.name}')?['ipv4_prefixes']"
    actions = {
      Append_to_TrafficManagerV4IPs = {
        type     = "AppendToArrayVariable"
        runAfter = {}
        inputs = {
          name  = "TrafficManagerV4IPs"
          value = "@items('For_Each_IPv4_Prefix')?['ip_prefix']"
        }
      }
    }
  })
}

#
# Branch 2 - Get IP Group
#

# Using a custom action as the http action resource doesn't support authentication property
resource "azurerm_logic_app_action_custom" "get_ip_group" {
  name         = "Get_Current_IP_Group"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "Http"
    inputs = {
      uri            = "https://management.azure.com@{parameters('IpGroupResourceId')}?api-version=2021-02-01"
      method         = "GET"
      authentication = { type = "ManagedServiceIdentity" }
    }
  })
}

resource "azurerm_logic_app_action_custom" "parse_ip_group_response" {
  name         = "Parse_IP_Group_Response"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "ParseJson"
    runAfter = {
      (azurerm_logic_app_action_custom.get_ip_group.name) = ["Succeeded"]
    }
    inputs = {
      content = "@body('${azurerm_logic_app_action_custom.get_ip_group.name}')"
      schema = {
        type = "object"
        properties = {
          etag     = { type = "string" }
          id       = { type = "string" }
          location = { type = "string" }
          name     = { type = "string" }
          type     = { type = "string" }
          properties = {
            type = "object"
            properties = {
              firewallPolicies = { type = "array" }
              firewalls        = { type = "array" }
              ipAddresses = {
                type  = "array"
                items = { type = "string" }
              }
              provisioningState = { type = "string" }
            }
          }
        }
      }
    }
  })
}

# Using a custom action as the http action resource doesn't support authentication property
resource "azurerm_logic_app_action_custom" "get_ip_group_tags" {
  name         = "Get_IP_Group_Tags"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "Http"
    runAfter = {
      (azurerm_logic_app_action_custom.parse_ip_group_response.name) = ["Succeeded"]
    }
    inputs = {
      uri            = "https://management.azure.com@{parameters('IpGroupResourceId')}/providers/Microsoft.Resources/tags/default?api-version=2021-04-01"
      method         = "GET"
      authentication = { type = "ManagedServiceIdentity" }
    }
  })
}

resource "azurerm_logic_app_action_custom" "parse_ip_group_tags" {
  name         = "Parse_IP_Group_Tags"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "ParseJson"
    runAfter = {
      (azurerm_logic_app_action_custom.get_ip_group_tags.name) = ["Succeeded"]
    }
    inputs = {
      content = "@body('Get_IP_Group_Tags')"
      schema = {
        properties = {
          type = "object"
          id   = { type = "string" }
          name = { type = "string" }
          type = { type = "string" }
          properties = {
            type = "object"
            properties = {
              tags = { type = "object" }
            }
          }
        }
      }
    }
  })
}

#
# Merge Branches 1 & 2
#
resource "azurerm_logic_app_action_custom" "update_ip_group" {
  name         = "Update_IP_Group"
  logic_app_id = azurerm_logic_app_workflow.tm_ipgroup.id

  body = jsonencode({
    type = "Http"
    runAfter = {
      (azurerm_logic_app_action_custom.for_each_tm_v4_ip.name)   = ["Succeeded"]
      (azurerm_logic_app_action_custom.parse_ip_group_tags.name) = ["Succeeded"]
    }
    inputs = {
      uri            = "https://management.azure.com@{parameters('IpGroupResourceId')}?api-version=2021-02-01"
      method         = "PUT"
      authentication = { type = "ManagedServiceIdentity" }
      body = {
        location = "@body('${azurerm_logic_app_action_custom.parse_ip_group_response.name}')?['location']",
        "properties" : {
          "firewallPolicies" : "@body('${azurerm_logic_app_action_custom.parse_ip_group_response.name}')?['properties']?['firewallPolicies']",
          "firewalls" : "@body('${azurerm_logic_app_action_custom.parse_ip_group_response.name}')?['properties']?['firewalls']",
          "ipAddresses" : "@variables('TrafficManagerV4IPs')"
        },
        "tags" : "@body('${azurerm_logic_app_action_custom.parse_ip_group_tags.name}')?['properties']?['tags']"
      }
    }
  })
}
