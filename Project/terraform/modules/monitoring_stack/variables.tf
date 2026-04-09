variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "prometheus_vm_name" {
  type = string
}

variable "prometheus_ip" {
  type = string
}

variable "grafana_vm_name" {
  type = string
}

variable "grafana_ip" {
  type = string
}

variable "internal_network_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
