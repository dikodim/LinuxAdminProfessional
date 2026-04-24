variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "edge_gateway_name" {
  type = string
}

variable "public_ip" {
  type = string
}

variable "allowed_source_ipset" {
  type = object({
    name         = string
    ip_addresses = list(string)
  })
  default = null
}

variable "external_network_name" {
  type = string
}

variable "dmz_network_name" {
  type = string
}

variable "dmz_subnet_cidr" {
  type = string
}

variable "dmz_gateway_ip" {
  type = string
}

variable "internal_network_name" {
  type = string
}

variable "internal_subnet_cidr" {
  type = string
}

variable "internal_gateway_ip" {
  type = string
}

variable "ssh_port_forwards" {
  type = list(object({
    name          = string
    internal_ip   = string
    external_port = number
  }))
}

variable "nextcloud_dmz_ips" {
  type = list(string)
}

variable "nextcloud_vip_ip" {
  type = string
}

variable "postgres_internal_ips" {
  type = list(string)
}

variable "services_internal_ip" {
  type = string
}

variable "tags" {
  type = map(string)
}
