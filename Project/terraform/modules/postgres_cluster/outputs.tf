output "node_names" {
  value = [
    format("%s-primary", var.cluster_name),
    format("%s-replica", var.cluster_name),
  ]
}
