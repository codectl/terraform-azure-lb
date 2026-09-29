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

    subnets = {
      private = {
        address_prefixes       = ["10.19.1.0/24"]
        network_security_group = {}
      }
    }
  }
}

module "lb" {
  source  = "codectl/lb/azure"
  version = "~> 1.0"

  loadbalancer = {
    name                = module.naming.lb.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    sku                 = "Gateway"

    frontend_ip_configurations = {
      private = {
        subnet_id = module.network.subnets.private.id
      }
    }

    backend_pools = {
      pool1 = {
        virtual_network_id = module.network.vnet.id
        tunnel_interfaces = {
          internal = {
            identifier = "800"
            type       = "External"
            protocol   = "VXLAN"
            port       = 10800
          },
          external = {
            identifier = "801"
            type       = "Internal"
            protocol   = "VXLAN"
            port       = 10801
          }
        }
      }
    }
  }
}
