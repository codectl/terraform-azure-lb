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
        nat_rules = {
          ssh = {
            protocol                 = "Tcp"
            frontend_port_start      = 2200
            frontend_port_end        = 2299
            backend_port             = 22
            backend_address_pool_key = "web_pool"
          }
          rdp = {
            protocol                 = "Tcp"
            frontend_port_start      = 3300
            frontend_port_end        = 3399
            backend_port             = 3389
            backend_address_pool_key = "web_pool"
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
          }
        }
      }
    }
  }
}
