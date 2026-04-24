terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
    }
  }
}

data "vcd_catalog" "catalog" {
  name = var.catalog_name
  org  = var.catalog_org
}

data "vcd_catalog_vapp_template" "template" {
  catalog_id = data.vcd_catalog.catalog.id
  name       = var.template_name
}

locals {
  admin_password           = try(var.vm_customization.admin_password, null)
  ssh_authorized_key       = trimspace(coalesce(try(var.vm_customization.ssh_authorized_key, null), ""))
  customization_initscript = local.ssh_authorized_key == "" ? null : <<-EOT
    #!/bin/bash
    set -eu
    ssh_key=$(cat <<'EOF_SSH_KEY'
    ${local.ssh_authorized_key}
    EOF_SSH_KEY
    )

    for user_name in root ubuntu; do
      if getent passwd "$user_name" >/dev/null 2>&1; then
        home_dir=$(getent passwd "$user_name" | cut -d: -f6)
        primary_group=$(id -gn "$user_name")
        install -d -m 700 -o "$user_name" -g "$primary_group" "$home_dir/.ssh"
        touch "$home_dir/.ssh/authorized_keys"
        chown "$user_name":"$primary_group" "$home_dir/.ssh/authorized_keys"
        chmod 600 "$home_dir/.ssh/authorized_keys"

        if ! grep -qxF "$ssh_key" "$home_dir/.ssh/authorized_keys"; then
          printf '%s\n' "$ssh_key" >> "$home_dir/.ssh/authorized_keys"
        fi
      fi
    done
  EOT
  customization_enabled    = local.admin_password != null || local.customization_initscript != null
}

resource "vcd_vm" "this" {
  name             = var.vm_name
  computer_name    = var.vm_name
  vapp_template_id = data.vcd_catalog_vapp_template.template.id
  memory           = var.vm_memory_mb
  cpus             = var.vm_cpu
  power_on         = true
  storage_profile  = var.storage_profile

  dynamic "override_template_disk" {
    for_each = var.root_disk_size_mb == null ? [] : [1]

    content {
      bus_type        = "paravirtual"
      bus_number      = 0
      unit_number     = 0
      size_in_mb      = var.root_disk_size_mb
      iops            = var.root_disk_iops
      storage_profile = var.storage_profile
    }
  }

  network {
    type               = "org"
    name               = var.internal_network_name
    ip_allocation_mode = "MANUAL"
    ip                 = var.service_ip
    is_primary         = true
  }

  dynamic "customization" {
    for_each = local.customization_enabled ? [1] : []

    content {
      enabled                    = true
      admin_password             = local.admin_password
      allow_local_admin_password = local.admin_password != null ? true : null
      auto_generate_password     = local.admin_password != null ? false : null
      initscript                 = local.customization_initscript
    }
  }
}
