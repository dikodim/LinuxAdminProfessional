locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    platform    = "vcd"
    network     = "nsx-v"
  }
}

module "nsxv_edge" {
  source = "./modules/nsxv_edge"

  project_name          = var.project_name
  environment           = var.environment
  edge_gateway_name     = var.nsxv_edge.edge_gateway_name
  public_ip             = var.nsxv_edge.public_ip
  allowed_source_ipset  = try(var.nsxv_edge.allowed_source_ipset, null)
  external_network_name = var.nsxv_edge.external_network
  dmz_network_name      = var.nsxv_edge.dmz_network_name
  dmz_subnet_cidr       = var.nsxv_edge.dmz_subnet_cidr
  dmz_gateway_ip        = var.nsxv_edge.dmz_gateway_ip
  internal_network_name = var.nsxv_edge.internal_network_name
  internal_subnet_cidr  = var.nsxv_edge.internal_subnet_cidr
  internal_gateway_ip   = var.nsxv_edge.internal_gateway_ip
  ssh_port_forwards     = try(var.nsxv_edge.ssh_port_forwards, [])
  nextcloud_dmz_ips     = var.nextcloud_cluster.dmz_ips
  nextcloud_vip_ip      = var.nextcloud_cluster.vip_ip
  postgres_internal_ips = [
    var.postgres_cluster.primary_ip,
    var.postgres_cluster.replica_ip,
  ]
  services_internal_ip = var.services_node.service_ip
  tags                 = local.common_tags
}

module "nextcloud_cluster" {
  source = "./modules/nextcloud_cluster"

  project_name      = var.project_name
  environment       = var.environment
  catalog_org       = try(var.nextcloud_cluster.catalog_org, null)
  catalog_name      = var.nextcloud_cluster.catalog_name
  cluster_name      = var.nextcloud_cluster.cluster_name
  node_count        = var.nextcloud_cluster.node_count
  template_name     = var.nextcloud_cluster.template_name
  vm_cpu            = var.nextcloud_cluster.vm_cpu
  vm_memory_mb      = var.nextcloud_cluster.vm_memory_mb
  storage_profile   = try(var.nextcloud_cluster.storage_profile, null)
  root_disk_size_mb = try(var.nextcloud_cluster.root_disk_size_mb, null)
  vip_ip            = var.nextcloud_cluster.vip_ip
  dmz_network_name  = module.nsxv_edge.dmz_network_name
  dmz_ips           = var.nextcloud_cluster.dmz_ips
  edge_gateway_name = module.nsxv_edge.edge_gateway_name
  vm_customization  = var.vm_customization
  tags              = local.common_tags
}

module "postgres_cluster" {
  source = "./modules/postgres_cluster"

  project_name          = var.project_name
  environment           = var.environment
  catalog_org           = try(var.postgres_cluster.catalog_org, null)
  catalog_name          = var.postgres_cluster.catalog_name
  cluster_name          = var.postgres_cluster.cluster_name
  template_name         = var.postgres_cluster.template_name
  vm_cpu                = var.postgres_cluster.vm_cpu
  vm_memory_mb          = var.postgres_cluster.vm_memory_mb
  storage_profile       = try(var.postgres_cluster.storage_profile, null)
  root_disk_size_mb     = try(var.postgres_cluster.root_disk_size_mb, null)
  internal_network_name = module.nsxv_edge.internal_network_name
  primary_ip            = var.postgres_cluster.primary_ip
  replica_ip            = var.postgres_cluster.replica_ip
  vm_customization      = var.vm_customization
  tags                  = local.common_tags
}

module "services_node" {
  source = "./modules/services_node"

  project_name          = var.project_name
  environment           = var.environment
  vm_name               = var.services_node.vm_name
  catalog_org           = try(var.services_node.catalog_org, null)
  catalog_name          = var.services_node.catalog_name
  template_name         = var.services_node.template_name
  vm_cpu                = var.services_node.vm_cpu
  vm_memory_mb          = var.services_node.vm_memory_mb
  storage_profile       = try(var.services_node.storage_profile, null)
  root_disk_size_mb     = try(var.services_node.root_disk_size_mb, null)
  service_ip            = var.services_node.service_ip
  enable_prometheus     = var.services_node.enable_prometheus
  enable_grafana        = var.services_node.enable_grafana
  enable_victorialogs   = var.services_node.enable_victorialogs
  enable_backup         = var.services_node.enable_backup
  enable_nfs            = var.services_node.enable_nfs
  repository_type       = var.services_node.repository_type
  pg_dump_schedule      = var.services_node.pg_dump_schedule
  internal_network_name = module.nsxv_edge.internal_network_name
  vm_customization      = var.vm_customization
  tags                  = local.common_tags
}
