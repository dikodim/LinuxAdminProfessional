output "node_names" {
  value = sort(keys(vcd_vm.node))
}
