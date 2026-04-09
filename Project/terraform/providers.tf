provider "vcd" {
  user                 = var.vcd.user
  password             = var.vcd.password
  org                  = var.vcd.org
  vdc                  = var.vcd.vdc
  url                  = var.vcd.url
  max_retry_timeout    = var.vcd.max_retry_timeout
  allow_unverified_ssl = var.vcd.allow_unverified_ssl
}
