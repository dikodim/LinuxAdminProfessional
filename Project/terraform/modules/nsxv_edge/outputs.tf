output "edge_gateway_name" {
  value = var.edge_gateway_name
}

output "public_ip" {
  value = var.public_ip
}

output "dmz_network_name" {
  value = vcd_network_routed.dmz.name
}

output "internal_network_name" {
  value = vcd_network_routed.internal.name
}
