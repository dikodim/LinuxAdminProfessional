output "edge_gateway_name" {
  description = "Planned NSX-V Edge gateway name."
  value       = module.nsxv_edge.edge_gateway_name
}

output "public_ip" {
  description = "Public IP reserved for the NSX-V Edge / Nextcloud publishing."
  value       = module.nsxv_edge.public_ip
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

output "services_nodes" {
  description = "Planned shared services VM names."
  value       = module.services_node.node_names
}
