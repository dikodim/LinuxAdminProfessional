variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "edge_gateway_name" {
  type = string
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

variable "tags" {
  type = map(string)
}
