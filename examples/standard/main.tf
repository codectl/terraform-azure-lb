module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]
  }
}

module "public_ip" {
  source  = "codectl/pip/azure"
  version = "~> 1.0"

  public_ips = {
    pub = {
      name                = module.naming.public_ip.name
      location            = module.rg.groups.demo.location
      resource_group_name = module.rg.groups.demo.name
    }
  }
}

module "lb" {
  source  = "codectl/lb/azure"
  version = "~> 1.0"

  loadbalancer = {
    name                = module.naming.lb.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku                 = "Standard"

    frontend_ip_configurations = {
      public = {
        public_ip_address_id = module.public_ip.public_ips.pub.id
        nat_pools = {
          pool1 = {
            protocol            = "Tcp"
            frontend_port_start = 50000
            frontend_port_end   = 50119
            backend_port        = 22
          }
        }
        nat_rules = {
          rule1 = {
            protocol      = "Tcp"
            frontend_port = 3389
            backend_port  = 3389
          }
        }
      }
    }

    backend_pools = {
      web_pool = {
        addresses = {
          server1 = {
            virtual_network_id = module.network.vnet.id
            ip_address         = "10.19.1.4"
          },
          server2 = {
            virtual_network_id = module.network.vnet.id
            ip_address         = "10.19.1.5"
          }
        }
        rules = {
          http = {
            protocol                       = "Tcp"
            frontend_port                  = 80
            backend_port                   = 80
            frontend_ip_configuration_name = "public"
            disable_outbound_snat          = true
            probe = {
              protocol     = "Http"
              port         = 80
              request_path = "/"
            }
          }
        }
        outbound_rules = {
          outbound1 = {
            protocol                   = "Tcp"
            frontend_ip_configurations = ["public"]
          }
        }
      }
    }
  }
}
