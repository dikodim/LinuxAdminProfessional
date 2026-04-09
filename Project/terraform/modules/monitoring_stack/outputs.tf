output "node_names" {
  value = [
    var.prometheus_vm_name,
    var.grafana_vm_name,
  ]
}
