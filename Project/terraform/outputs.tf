output "edge_gateway_name" {
  description = "Planned NSX-V Edge gateway name."
  value       = module.nsxv_edge.edge_gateway_name
}

output "dmz_network_name" {
  description = "Planned DMZ network name."
  value       = module.nsxv_edge.dmz_network_name
}

output "internal_network_name" {
  description = "Planned internal network name."
  value       = module.nsxv_edge.internal_network_name
}

output "nextcloud_nodes" {
  description = "Planned Nextcloud VM names."
  value       = module.nextcloud_cluster.node_names
}

output "postgres_nodes" {
  description = "Planned PostgreSQL VM names."
  value       = module.postgres_cluster.node_names
}

output "monitoring_nodes" {
  description = "Planned monitoring VM names."
  value       = module.monitoring_stack.node_names
}

output "backup_nodes" {
  description = "Planned backup VM names."
  value       = module.backup_stack.node_names
}
