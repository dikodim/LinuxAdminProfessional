terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
    }
  }
}

data "vcd_edgegateway" "this" {
  name = var.edge_gateway_name
}

locals {
  dmz_to_postgres = {
    for pair in flatten([
      for source in var.nextcloud_dmz_ips : [
        for destination in var.postgres_internal_ips : {
          key         = format("%s-%s-5432", source, destination)
          source_ip   = source
          target_ip   = destination
          target_port = "5432"
        }
      ]
    ]) : pair.key => pair
  }
  ssh_port_forwards = {
    for item in var.ssh_port_forwards :
    item.name => item
  }
  dmz_to_services = {
    for pair in flatten([
      for source in var.nextcloud_dmz_ips : [
        for target_port in ["1514", "3000", "9090", "9428"] : {
          key         = format("%s-%s", source, target_port)
          source_ip   = source
          target_ip   = var.services_internal_ip
          target_port = target_port
        }
      ]
    ]) : pair.key => pair
  }
  services_to_nextcloud_exporters = {
    for pair in flatten([
      for destination in var.nextcloud_dmz_ips : [
        {
          key         = format("%s-9100", destination)
          source_ip   = var.services_internal_ip
          target_ip   = destination
          target_port = "9100"
        }
      ]
    ]) : pair.key => pair
  }
  services_to_postgres_exporters = {
    for pair in flatten([
      for destination in var.postgres_internal_ips : [
        {
          key         = format("%s-9187", destination)
          source_ip   = var.services_internal_ip
          target_ip   = destination
          target_port = "9187"
        }
      ]
    ]) : pair.key => pair
  }
}

resource "vcd_nsxv_ip_set" "allowed_sources" {
  count = var.allowed_source_ipset == null ? 0 : 1

  name         = var.allowed_source_ipset.name
  ip_addresses = var.allowed_source_ipset.ip_addresses
}

resource "vcd_network_routed" "dmz" {
  name         = var.dmz_network_name
  edge_gateway = data.vcd_edgegateway.this.name
  gateway      = var.dmz_gateway_ip
  netmask      = cidrnetmask(var.dmz_subnet_cidr)

  static_ip_pool {
    start_address = cidrhost(var.dmz_subnet_cidr, 10)
    end_address   = cidrhost(var.dmz_subnet_cidr, 200)
  }
}

resource "vcd_network_routed" "internal" {
  name         = var.internal_network_name
  edge_gateway = data.vcd_edgegateway.this.name
  gateway      = var.internal_gateway_ip
  netmask      = cidrnetmask(var.internal_subnet_cidr)

  static_ip_pool {
    start_address = cidrhost(var.internal_subnet_cidr, 10)
    end_address   = cidrhost(var.internal_subnet_cidr, 200)
  }
}

resource "vcd_nsxv_dnat" "nextcloud_https" {
  edge_gateway       = data.vcd_edgegateway.this.name
  network_type       = "ext"
  network_name       = var.external_network_name
  original_address   = var.public_ip
  original_port      = "443"
  translated_address = var.nextcloud_vip_ip
  translated_port    = "443"
  protocol           = "tcp"
}

resource "vcd_nsxv_snat" "dmz_egress" {
  edge_gateway       = data.vcd_edgegateway.this.name
  network_type       = "ext"
  network_name       = var.external_network_name
  original_address   = var.dmz_subnet_cidr
  translated_address = var.public_ip
}

resource "vcd_nsxv_snat" "internal_egress" {
  edge_gateway       = data.vcd_edgegateway.this.name
  network_type       = "ext"
  network_name       = var.external_network_name
  original_address   = var.internal_subnet_cidr
  translated_address = var.public_ip
}

resource "vcd_nsxv_firewall_rule" "allow_https_from_whitelist" {
  count = var.allowed_source_ipset != null ? 1 : 0

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = "allow-https-whitelist"
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_sets = [vcd_nsxv_ip_set.allowed_sources[0].name]
  }

  destination {
    ip_addresses = [var.public_ip]
  }

  service {
    protocol    = "tcp"
    port        = "443"
    source_port = "any"
  }

  depends_on = [vcd_nsxv_ip_set.allowed_sources]
}

resource "vcd_nsxv_firewall_rule" "allow_nextcloud_to_postgres" {
  for_each = local.dmz_to_postgres

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = format("allow-db-%s", each.key)
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [each.value.source_ip]
  }

  destination {
    ip_addresses = [each.value.target_ip]
  }

  service {
    protocol    = "tcp"
    port        = each.value.target_port
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_nextcloud_to_nfs" {
  for_each = toset(var.nextcloud_dmz_ips)

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = format("allow-nfs-%s", replace(each.value, ".", "-"))
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [each.value]
  }

  destination {
    ip_addresses = [var.services_internal_ip]
  }

  service {
    protocol    = "tcp"
    port        = "2049"
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_nextcloud_to_services" {
  for_each = local.dmz_to_services

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = format("allow-services-%s", each.key)
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [each.value.source_ip]
  }

  destination {
    ip_addresses = [each.value.target_ip]
  }

  service {
    protocol    = "tcp"
    port        = each.value.target_port
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_services_to_nextcloud_exporters" {
  for_each = local.services_to_nextcloud_exporters

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = format("allow-exporter-%s", each.key)
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [each.value.source_ip]
  }

  destination {
    ip_addresses = [each.value.target_ip]
  }

  service {
    protocol    = "tcp"
    port        = each.value.target_port
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_services_to_postgres_exporters" {
  for_each = local.services_to_postgres_exporters

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = format("allow-pg-exporter-%s", each.key)
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [each.value.source_ip]
  }

  destination {
    ip_addresses = [each.value.target_ip]
  }

  service {
    protocol    = "tcp"
    port        = each.value.target_port
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_dmz_egress_dns" {
  edge_gateway    = data.vcd_edgegateway.this.name
  name            = "allow-dmz-egress-dns"
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [var.dmz_subnet_cidr]
  }

  destination {
    ip_addresses = ["any"]
  }

  service {
    protocol    = "udp"
    port        = "53"
    source_port = "any"
  }

  service {
    protocol    = "tcp"
    port        = "53"
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_dmz_egress_web" {
  edge_gateway    = data.vcd_edgegateway.this.name
  name            = "allow-dmz-egress-web"
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [var.dmz_subnet_cidr]
  }

  destination {
    ip_addresses = ["any"]
  }

  service {
    protocol    = "tcp"
    port        = "80"
    source_port = "any"
  }

  service {
    protocol    = "tcp"
    port        = "443"
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_internal_egress_dns" {
  edge_gateway    = data.vcd_edgegateway.this.name
  name            = "allow-internal-egress-dns"
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [var.internal_subnet_cidr]
  }

  destination {
    ip_addresses = ["any"]
  }

  service {
    protocol    = "udp"
    port        = "53"
    source_port = "any"
  }

  service {
    protocol    = "tcp"
    port        = "53"
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_internal_egress_web" {
  edge_gateway    = data.vcd_edgegateway.this.name
  name            = "allow-internal-egress-web"
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [var.internal_subnet_cidr]
  }

  destination {
    ip_addresses = ["any"]
  }

  service {
    protocol    = "tcp"
    port        = "80"
    source_port = "any"
  }

  service {
    protocol    = "tcp"
    port        = "443"
    source_port = "any"
  }
}

resource "vcd_nsxv_firewall_rule" "allow_services_egress_smtp" {
  edge_gateway    = data.vcd_edgegateway.this.name
  name            = "allow-services-egress-smtp"
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_addresses = [var.services_internal_ip]
  }

  destination {
    ip_addresses = ["any"]
  }

  service {
    protocol    = "tcp"
    port        = "587"
    source_port = "any"
  }
}

resource "vcd_nsxv_dnat" "ssh" {
  for_each = local.ssh_port_forwards

  edge_gateway       = data.vcd_edgegateway.this.name
  network_type       = "ext"
  network_name       = var.external_network_name
  original_address   = var.public_ip
  original_port      = tostring(each.value.external_port)
  translated_address = each.value.internal_ip
  translated_port    = "22"
  protocol           = "tcp"
}

resource "vcd_nsxv_firewall_rule" "allow_ssh_from_whitelist" {
  for_each = local.ssh_port_forwards

  edge_gateway    = data.vcd_edgegateway.this.name
  name            = format("allow-ssh-%s", each.key)
  action          = "accept"
  enabled         = true
  logging_enabled = false

  source {
    ip_sets = [vcd_nsxv_ip_set.allowed_sources[0].name]
  }

  destination {
    ip_addresses = [var.public_ip]
  }

  service {
    protocol    = "tcp"
    port        = tostring(each.value.external_port)
    source_port = "any"
  }

  depends_on = [vcd_nsxv_dnat.ssh, vcd_nsxv_ip_set.allowed_sources]
}
