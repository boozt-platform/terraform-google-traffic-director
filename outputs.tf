# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "backend_service" {
  description = "The created backend service resource attributes."
  value = {
    name         = google_compute_backend_service.this.name
    id           = google_compute_backend_service.this.id
    self_link    = google_compute_backend_service.this.self_link
    generated_id = google_compute_backend_service.this.generated_id
  }
}

output "tcp_proxy" {
  description = "The created TCP proxy resource attributes. Null when create_forwarding_rule is false."
  value = var.create_forwarding_rule ? {
    name      = google_compute_target_tcp_proxy.this[0].name
    id        = google_compute_target_tcp_proxy.this[0].id
    self_link = google_compute_target_tcp_proxy.this[0].self_link
    proxy_id  = google_compute_target_tcp_proxy.this[0].proxy_id
  } : null
}

output "forwarding_rule" {
  description = "The created forwarding rule resource attributes. Null when create_forwarding_rule is false."
  value = var.create_forwarding_rule ? {
    name      = google_compute_global_forwarding_rule.this[0].name
    id        = google_compute_global_forwarding_rule.this[0].id
    self_link = google_compute_global_forwarding_rule.this[0].self_link
  } : null
}
