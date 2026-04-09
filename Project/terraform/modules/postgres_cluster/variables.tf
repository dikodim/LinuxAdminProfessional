variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
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

variable "internal_network_name" {
  type = string
}

variable "primary_ip" {
  type = string
}

variable "replica_ip" {
  type = string
}

variable "tags" {
  type = map(string)
}
