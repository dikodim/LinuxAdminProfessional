output "node_names" {
  value = [
    for index in range(var.node_count) :
    format("%s-%02d", var.cluster_name, index + 1)
  ]
}
