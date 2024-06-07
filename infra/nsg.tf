data "http" "current_public_ip" {
  url = "https://ipinfo.io/ip"
}

resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowConnectionsFromPublicIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["25565", "443"]
    source_address_prefixes    = [data.http.current_public_ip.body]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "apps" {
  subnet_id                 = azurerm_subnet.apps.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
