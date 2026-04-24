variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "catalog_org" {
  type    = string
  default = null
}

variable "catalog_name" {
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

variable "storage_profile" {
  type    = string
  default = null
}

variable "root_disk_size_mb" {
  type    = number
  default = null
}

variable "root_disk_iops" {
  type    = number
  default = 7000
}

variable "vip_ip" {
  type = string
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

variable "vm_customization" {
  type = object({
    admin_password     = optional(string)
    ssh_authorized_key = optional(string)
  })
}
