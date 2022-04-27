variable "client_id" {}
variable "client_secret" {}

resource "azurerm_resource_group" "rg_diplomado" {
  name     = "rg_diplomado"
  location = "centralus"
  tags = {
    "env"   = "dev"
    "owner" = "grupo4"
  }
}

resource "azurerm_virtual_network" "vn_diplomado" {
  name                = "vn_diplomado"
  address_space       = ["11.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg_diplomado.name
  location            = azurerm_resource_group.rg_diplomado.location
}

resource "azurerm_subnet" "subnet_diplomado" {
  name                 = "subnet_diplomado"
  resource_group_name  = azurerm_resource_group.rg_diplomado.name
  virtual_network_name = azurerm_virtual_network.vn_diplomado.name
  address_prefixes     = ["11.0.0.0/24"]
}

resource "azurerm_container_registry" "acr_diplomado" {
  name                = "acrdiplomado"
  resource_group_name = azurerm_resource_group.rg_diplomado.name
  location            = azurerm_resource_group.rg_diplomado.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks_cluster_diplomado" {
  name                              = "aks_cluster_diplomado"
  location                          = azurerm_resource_group.rg_diplomado.location
  resource_group_name               = azurerm_resource_group.rg_diplomado.name
  dns_prefix                        = "grupo4"
  role_based_access_control_enabled = true
  kubernetes_version                = "1.22"

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = "standard_ds2"
    vnet_subnet_id      = azurerm_subnet.subnet_diplomado.id
    enable_auto_scaling = true
    max_count           = 3
    min_count           = 1
    max_pods            = 80
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "np_extra" {
  name                  = "extra"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster_diplomado.id
  vm_size               = "standard_ds2"
  vnet_subnet_id        = azurerm_subnet.subnet_diplomado.id
  node_count            = 1
  enable_auto_scaling   = true
  max_count             = 3
  min_count             = 1
  max_pods              = 80
  node_labels           = { tipo : "adicional" }
}

