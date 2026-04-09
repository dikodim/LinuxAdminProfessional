variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "node_count" {
  type = number
}

variable "template_name" {
  type = string
}

variable "vm_cpu" {
  type = number
}

variable "vm_memory_mb" {
  type = number
}

variable "dmz_network_name" {
  type = string
}

variable "dmz_ips" {
  type = list(string)
}

variable "edge_gateway_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
