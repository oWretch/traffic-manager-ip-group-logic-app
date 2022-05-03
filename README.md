# Traffic Manager IP Group Logic App

While Microsoft provide a Service Tag for Traffic Manager IPs, [it's not usable with Azure Firewall in DNAT rules.][blog-post]
The simplest workaround for this problem is a Logic App which fetches the latest list of Traffic Manager IP addresses and stores them in an IP Group.
This IP group can then be added as a source address in the Azure Firewall DNAT rule, allowing restriction of inbound traffic when using Traffic Manager for load distribution.

[blog-post]: https://solideogloria.tech/azure/traffic-manager-ip-group.html
