variable "project_name" {
  description = "Logical project name used in resource naming."
  type        = string
  default     = "nextcloud-nsxv-lab"
}

variable "environment" {
  description = "Environment name used in tags and naming."
  type        = string
  default     = "lab"
}

variable "vcd" {
  description = "VMware Cloud Director provider settings."
  type = object({
    user                 = string
    password             = string
    org                  = string
    vdc                  = string
    url                  = string
    max_retry_timeout    = optional(number, 60)
    allow_unverified_ssl = optional(bool, true)
  })
  sensitive = true
}

variable "nsxv_edge" {
  description = "NSX-V Edge and routed network settings."
  type = object({
    edge_gateway_name     = string
    external_network      = string
    dmz_network_name      = string
    dmz_subnet_cidr       = string
    dmz_gateway_ip        = string
    internal_network_name = string
    internal_subnet_cidr  = string
    internal_gateway_ip   = string
  })
}

variable "nextcloud_cluster" {
  description = "Nextcloud application tier settings."
  type = object({
    cluster_name  = string
    node_count    = number
    template_name = string
    vm_cpu        = number
    vm_memory_mb  = number
    dmz_ips       = list(string)
  })
}

variable "postgres_cluster" {
  description = "PostgreSQL primary/replica settings."
  type = object({
    cluster_name  = string
    template_name = string
    vm_cpu        = number
    vm_memory_mb  = number
    primary_ip    = string
    replica_ip    = string
  })
}

variable "monitoring_stack" {
  description = "Monitoring stack settings for Prometheus and Grafana."
  type = object({
    prometheus_vm_name = string
    prometheus_ip      = string
    grafana_vm_name    = string
    grafana_ip         = string
  })
}

variable "backup_stack" {
  description = "Backup stack settings."
  type = object({
    backup_vm_name   = string
    backup_ip        = string
    repository_type  = string
    pg_dump_schedule = string
  })
}
