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
  description = "The created TCP proxy resource attributes."
  value = {
    name      = google_compute_target_tcp_proxy.this.name
    id        = google_compute_target_tcp_proxy.this.id
    self_link = google_compute_target_tcp_proxy.this.self_link
    proxy_id  = google_compute_target_tcp_proxy.this.proxy_id
  }
}

output "forwarding_rule" {
  description = "The created forwarding rule resource attributes."
  value = {
    name      = google_compute_global_forwarding_rule.this.name
    id        = google_compute_global_forwarding_rule.this.id
    self_link = google_compute_global_forwarding_rule.this.self_link
  }
}
