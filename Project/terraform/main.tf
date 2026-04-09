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
  external_network_name = var.nsxv_edge.external_network
  dmz_network_name      = var.nsxv_edge.dmz_network_name
  dmz_subnet_cidr       = var.nsxv_edge.dmz_subnet_cidr
  dmz_gateway_ip        = var.nsxv_edge.dmz_gateway_ip
  internal_network_name = var.nsxv_edge.internal_network_name
  internal_subnet_cidr  = var.nsxv_edge.internal_subnet_cidr
  internal_gateway_ip   = var.nsxv_edge.internal_gateway_ip
  tags                  = local.common_tags
}

module "nextcloud_cluster" {
  source = "./modules/nextcloud_cluster"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = var.nextcloud_cluster.cluster_name
  node_count        = var.nextcloud_cluster.node_count
  template_name     = var.nextcloud_cluster.template_name
  vm_cpu            = var.nextcloud_cluster.vm_cpu
  vm_memory_mb      = var.nextcloud_cluster.vm_memory_mb
  dmz_network_name  = var.nsxv_edge.dmz_network_name
  dmz_ips           = var.nextcloud_cluster.dmz_ips
  edge_gateway_name = module.nsxv_edge.edge_gateway_name
  tags              = local.common_tags
}

module "postgres_cluster" {
  source = "./modules/postgres_cluster"

  project_name          = var.project_name
  environment           = var.environment
  cluster_name          = var.postgres_cluster.cluster_name
  template_name         = var.postgres_cluster.template_name
  vm_cpu                = var.postgres_cluster.vm_cpu
  vm_memory_mb          = var.postgres_cluster.vm_memory_mb
  internal_network_name = var.nsxv_edge.internal_network_name
  primary_ip            = var.postgres_cluster.primary_ip
  replica_ip            = var.postgres_cluster.replica_ip
  tags                  = local.common_tags
}

module "monitoring_stack" {
  source = "./modules/monitoring_stack"

  project_name          = var.project_name
  environment           = var.environment
  prometheus_vm_name    = var.monitoring_stack.prometheus_vm_name
  prometheus_ip         = var.monitoring_stack.prometheus_ip
  grafana_vm_name       = var.monitoring_stack.grafana_vm_name
  grafana_ip            = var.monitoring_stack.grafana_ip
  internal_network_name = var.nsxv_edge.internal_network_name
  tags                  = local.common_tags
}

module "backup_stack" {
  source = "./modules/backup_stack"

  project_name          = var.project_name
  environment           = var.environment
  backup_vm_name        = var.backup_stack.backup_vm_name
  backup_ip             = var.backup_stack.backup_ip
  repository_type       = var.backup_stack.repository_type
  pg_dump_schedule      = var.backup_stack.pg_dump_schedule
  internal_network_name = var.nsxv_edge.internal_network_name
  tags                  = local.common_tags
}
