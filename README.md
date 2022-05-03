# Traffic Manager IP Group Logic App

While Microsoft provide a Service Tag for Traffic Manager IPs, [it's not usable with Azure Firewall in DNAT rules.][blog-post]
The simplest workaround for this problem is a Logic App which fetches the latest list of Traffic Manager IP addresses and stores them in an IP Group.
This IP group can then be added as a source address in the Azure Firewall DNAT rule, allowing restriction of inbound traffic when using Traffic Manager for load distribution.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FoWretch%2Ftraffic-manager-ip-group-logic-app%2Fmaster%2FARM%2Fazuredeploy.json)
[![Deploy To Azure US Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FoWretch%2Ftraffic-manager-ip-group-logic-app%2Fmaster%2FARM%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FoWretch%2Ftraffic-manager-ip-group-logic-app%2Fmaster%2FARM%2Fazuredeploy.json)

[blog-post]: https://solideogloria.tech/azure/traffic-manager-ip-group.html
