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
    edge_gateway_name = string
    public_ip         = string
    allowed_source_ipset = optional(object({
      name         = string
      ip_addresses = list(string)
    }), null)
    external_network      = string
    dmz_network_name      = string
    dmz_subnet_cidr       = string
    dmz_gateway_ip        = string
    internal_network_name = string
    internal_subnet_cidr  = string
    internal_gateway_ip   = string
    ssh_port_forwards = optional(list(object({
      name          = string
      internal_ip   = string
      external_port = number
    })), [])
  })
}

variable "nextcloud_cluster" {
  description = "Nextcloud application tier settings."
  type = object({
    catalog_org       = optional(string)
    catalog_name      = string
    cluster_name      = string
    node_count        = number
    template_name     = string
    vm_cpu            = number
    vm_memory_mb      = number
    storage_profile   = optional(string)
    root_disk_size_mb = optional(number)
    vip_ip            = string
    dmz_ips           = list(string)
  })
}

variable "postgres_cluster" {
  description = "PostgreSQL primary/replica settings."
  type = object({
    catalog_org       = optional(string)
    catalog_name      = string
    cluster_name      = string
    template_name     = string
    vm_cpu            = number
    vm_memory_mb      = number
    storage_profile   = optional(string)
    root_disk_size_mb = optional(number)
    primary_ip        = string
    replica_ip        = string
  })
}

variable "services_node" {
  description = "Shared internal services node for monitoring, backup and NFS."
  type = object({
    vm_name             = string
    catalog_org         = optional(string)
    catalog_name        = string
    template_name       = string
    vm_cpu              = number
    vm_memory_mb        = number
    storage_profile     = optional(string)
    root_disk_size_mb   = optional(number)
    service_ip          = string
    enable_prometheus   = bool
    enable_grafana      = bool
    enable_victorialogs = bool
    enable_backup       = bool
    enable_nfs          = bool
    repository_type     = string
    pg_dump_schedule    = string
  })
}

variable "vm_customization" {
  description = "Optional guest customization for all Linux VMs."
  type = object({
    admin_password     = optional(string)
    ssh_authorized_key = optional(string)
  })
  default   = {}
  sensitive = true
}
