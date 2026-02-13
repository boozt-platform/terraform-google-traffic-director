# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

# Terraform Native Tests for GCP Service Mesh Module
#
# Run with: terraform test
#
# Note: These tests use mocked providers to avoid creating real resources.
# For integration tests, use the examples/ directory with a real GCP project.

mock_provider "google" {}

variables {
  project_id      = "test-project"
  network         = "default"
  name            = "test-service"
  port_name       = "redis"
  port_range      = "6379"
  health_check_id = "projects/test-project/global/healthChecks/test-hc"
  instance_groups = ["projects/test-project/regions/us-central1/instanceGroups/test-ig"]
}

# -----------------------------------------------------------------------------
# Basic Configuration Tests
# -----------------------------------------------------------------------------

run "basic_configuration" {
  command = plan

  assert {
    condition     = google_compute_backend_service.this.name == "test-service-bs"
    error_message = "Backend service name should be 'test-service-bs'"
  }

  assert {
    condition     = google_compute_backend_service.this.load_balancing_scheme == "INTERNAL_SELF_MANAGED"
    error_message = "Load balancing scheme should be INTERNAL_SELF_MANAGED"
  }

  assert {
    condition     = google_compute_backend_service.this.protocol == "TCP"
    error_message = "Protocol should be TCP"
  }

  assert {
    condition     = google_compute_target_tcp_proxy.this[0].name == "test-service-proxy"
    error_message = "TCP proxy name should be 'test-service-proxy'"
  }

  assert {
    condition     = google_compute_global_forwarding_rule.this[0].name == "test-service"
    error_message = "Forwarding rule name should be 'test-service'"
  }

  assert {
    condition     = google_compute_global_forwarding_rule.this[0].port_range == "6379"
    error_message = "Forwarding rule port range should be '6379'"
  }
}

# -----------------------------------------------------------------------------
# Backend Service Only (no forwarding rule) Tests
# -----------------------------------------------------------------------------

run "backend_service_only" {
  command = plan

  variables {
    create_forwarding_rule = false
  }

  assert {
    condition     = google_compute_backend_service.this.name == "test-service-bs"
    error_message = "Backend service should still be created"
  }

  assert {
    condition     = google_compute_backend_service.this.load_balancing_scheme == "INTERNAL_SELF_MANAGED"
    error_message = "Load balancing scheme should be INTERNAL_SELF_MANAGED"
  }

  assert {
    condition     = length(google_compute_target_tcp_proxy.this) == 0
    error_message = "TCP proxy should not be created when create_forwarding_rule is false"
  }

  assert {
    condition     = length(google_compute_global_forwarding_rule.this) == 0
    error_message = "Forwarding rule should not be created when create_forwarding_rule is false"
  }
}

# -----------------------------------------------------------------------------
# Round-Robin Configuration Tests
# -----------------------------------------------------------------------------

run "round_robin_configuration" {
  command = plan

  variables {
    locality_lb_policy = "ROUND_ROBIN"
    session_affinity   = "NONE"
  }

  assert {
    condition     = google_compute_backend_service.this.locality_lb_policy == "ROUND_ROBIN"
    error_message = "Locality LB policy should be ROUND_ROBIN"
  }

  assert {
    condition     = google_compute_backend_service.this.session_affinity == "NONE"
    error_message = "Session affinity should be NONE"
  }
}

# -----------------------------------------------------------------------------
# Sticky Session (RING_HASH) Configuration Tests
# -----------------------------------------------------------------------------

run "sticky_session_configuration" {
  command = plan

  variables {
    locality_lb_policy = "RING_HASH"
    session_affinity   = "CLIENT_IP"
  }

  assert {
    condition     = google_compute_backend_service.this.locality_lb_policy == "RING_HASH"
    error_message = "Locality LB policy should be RING_HASH"
  }

  assert {
    condition     = google_compute_backend_service.this.session_affinity == "CLIENT_IP"
    error_message = "Session affinity should be CLIENT_IP"
  }
}

# -----------------------------------------------------------------------------
# Circuit Breaker Configuration Tests
# -----------------------------------------------------------------------------

run "circuit_breaker_configuration" {
  command = plan

  variables {
    circuit_breakers = {
      max_connections      = 1024
      max_pending_requests = 500
      max_requests         = 2000
      max_retries          = 3
    }
  }

  assert {
    condition     = length(google_compute_backend_service.this.circuit_breakers) == 1
    error_message = "Circuit breakers should be configured"
  }
}

# -----------------------------------------------------------------------------
# Outlier Detection Configuration Tests
# -----------------------------------------------------------------------------

run "outlier_detection_configuration" {
  command = plan

  variables {
    outlier_detection = {
      consecutive_errors   = 5
      max_ejection_percent = 50
      interval = {
        seconds = 10
      }
      base_ejection_time = {
        seconds = 30
      }
    }
  }

  assert {
    condition     = length(google_compute_backend_service.this.outlier_detection) == 1
    error_message = "Outlier detection should be configured"
  }
}

# -----------------------------------------------------------------------------
# Timeout Configuration Tests
# -----------------------------------------------------------------------------

run "timeout_configuration" {
  command = plan

  variables {
    timeout_sec                     = 60
    connection_draining_timeout_sec = 120
  }

  assert {
    condition     = google_compute_backend_service.this.timeout_sec == 60
    error_message = "Timeout should be 60 seconds"
  }

  assert {
    condition     = google_compute_backend_service.this.connection_draining_timeout_sec == 120
    error_message = "Connection draining timeout should be 120 seconds"
  }
}

# -----------------------------------------------------------------------------
# Labels Configuration Tests
# -----------------------------------------------------------------------------

run "labels_configuration" {
  command = plan

  variables {
    labels = {
      environment = "test"
      team        = "platform"
    }
  }

  assert {
    condition     = google_compute_global_forwarding_rule.this[0].labels["environment"] == "test"
    error_message = "Label 'environment' should be 'test'"
  }

  assert {
    condition     = google_compute_global_forwarding_rule.this[0].labels["team"] == "platform"
    error_message = "Label 'team' should be 'platform'"
  }
}

# -----------------------------------------------------------------------------
# Logging Configuration Tests
# -----------------------------------------------------------------------------

run "logging_enabled" {
  command = plan

  variables {
    log_config_enable      = true
    log_config_sample_rate = 0.5
  }

  assert {
    condition     = google_compute_backend_service.this.log_config[0].enable == true
    error_message = "Logging should be enabled"
  }

  assert {
    condition     = google_compute_backend_service.this.log_config[0].sample_rate == 0.5
    error_message = "Sample rate should be 0.5"
  }
}

# -----------------------------------------------------------------------------
# Connection Limits Configuration Tests
# -----------------------------------------------------------------------------

run "connection_limits_configuration" {
  command = plan

  variables {
    max_connections              = 5000
    max_connections_per_instance = 1000
    balancing_mode               = "CONNECTION"
  }

  assert {
    condition     = length(google_compute_backend_service.this.backend) > 0
    error_message = "At least one backend should be configured"
  }
}
