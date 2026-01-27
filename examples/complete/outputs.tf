# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "backend_services" {
  description = "Map of backend service details"
  value = {
    for k, v in module.traffic_director : k => {
      name         = v.backend_service.name
      generated_id = v.backend_service.generated_id
    }
  }
}

output "forwarding_rules" {
  description = "Map of forwarding rule details"
  value = {
    for k, v in module.traffic_director : k => {
      name = v.forwarding_rule.name
      id   = v.forwarding_rule.id
    }
  }
}

output "health_check_id" {
  description = "The health check ID"
  value       = google_compute_health_check.redis.id
}

output "instance_group" {
  description = "The instance group URL"
  value       = google_compute_region_instance_group_manager.redis.instance_group
}

output "envoy_cluster_names" {
  description = "Envoy cluster names for client configuration"
  value = {
    for k, v in module.traffic_director : k => "cloud-internal-istio:cloud_mp_${data.google_project.current.number}_${v.backend_service.generated_id}"
  }
}
