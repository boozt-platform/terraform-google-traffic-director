# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

locals {
  # Resource naming
  backend_service_name = "${var.name}-bs"
  proxy_name           = "${var.name}-proxy"
  forwarding_rule_name = var.name
}
