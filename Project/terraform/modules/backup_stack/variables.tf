variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "backup_vm_name" {
  type = string
}

variable "backup_ip" {
  type = string
}

variable "repository_type" {
  type = string
}

variable "pg_dump_schedule" {
  type = string
}

variable "internal_network_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
