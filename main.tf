# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

resource "google_compute_backend_service" "this" {
  project                         = var.project_id
  name                            = local.backend_service_name
  protocol                        = "TCP" # INTERNAL_SELF_MANAGED only supports TCP
  load_balancing_scheme           = "INTERNAL_SELF_MANAGED"
  health_checks                   = [var.health_check_id]
  port_name                       = var.port_name
  timeout_sec                     = var.timeout_sec
  session_affinity                = var.session_affinity
  locality_lb_policy              = var.locality_lb_policy
  connection_draining_timeout_sec = var.connection_draining_timeout_sec

  dynamic "circuit_breakers" {
    for_each = var.circuit_breakers != null ? [var.circuit_breakers] : []
    content {
      max_connections      = lookup(circuit_breakers.value, "max_connections", null)
      max_pending_requests = lookup(circuit_breakers.value, "max_pending_requests", null)
      max_requests         = lookup(circuit_breakers.value, "max_requests", null)
      max_retries          = lookup(circuit_breakers.value, "max_retries", null)
    }
  }

  dynamic "outlier_detection" {
    for_each = var.outlier_detection != null ? [var.outlier_detection] : []
    content {
      consecutive_errors   = lookup(outlier_detection.value, "consecutive_errors", null)
      max_ejection_percent = lookup(outlier_detection.value, "max_ejection_percent", null)

      dynamic "interval" {
        for_each = lookup(outlier_detection.value, "interval", null) != null ? [outlier_detection.value.interval] : []
        content {
          seconds = lookup(interval.value, "seconds", null)
          nanos   = lookup(interval.value, "nanos", null)
        }
      }

      dynamic "base_ejection_time" {
        for_each = lookup(outlier_detection.value, "base_ejection_time", null) != null ? [outlier_detection.value.base_ejection_time] : []
        content {
          seconds = lookup(base_ejection_time.value, "seconds", null)
          nanos   = lookup(base_ejection_time.value, "nanos", null)
        }
      }
    }
  }

  log_config {
    enable      = var.log_config_enable
    sample_rate = var.log_config_sample_rate
  }

  dynamic "backend" {
    for_each = var.instance_groups
    content {
      group                        = backend.value
      balancing_mode               = var.balancing_mode
      max_connections              = var.max_connections
      max_connections_per_instance = var.max_connections_per_instance
    }
  }
}

resource "google_compute_target_tcp_proxy" "this" {
  count = var.create_forwarding_rule ? 1 : 0

  project         = var.project_id
  name            = local.proxy_name
  backend_service = google_compute_backend_service.this.id
}

resource "google_compute_global_forwarding_rule" "this" {
  count = var.create_forwarding_rule ? 1 : 0

  project               = var.project_id
  name                  = local.forwarding_rule_name
  target                = google_compute_target_tcp_proxy.this[0].id
  port_range            = var.port_range
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  network               = var.network
  ip_address            = var.ip_address
  labels                = var.labels
}
