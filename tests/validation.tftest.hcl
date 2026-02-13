# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

# Validation Tests for GCP Service Mesh Module
#
# These tests verify that input validation works correctly.

mock_provider "google" {}

# Base valid variables for override in tests
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
# Name Validation Tests
# -----------------------------------------------------------------------------

run "valid_name" {
  command = plan

  variables {
    name = "my-redis-service"
  }
}

run "valid_name_with_numbers" {
  command = plan

  variables {
    name = "redis-cache-01"
  }
}

run "invalid_name_starts_with_number" {
  command = plan

  variables {
    name = "1-invalid-name"
  }

  expect_failures = [var.name]
}

run "invalid_name_uppercase" {
  command = plan

  variables {
    name = "Invalid-Name"
  }

  expect_failures = [var.name]
}

run "invalid_name_ends_with_hyphen" {
  command = plan

  variables {
    name = "invalid-name-"
  }

  expect_failures = [var.name]
}

# -----------------------------------------------------------------------------
# Port Range Validation Tests
# -----------------------------------------------------------------------------

run "valid_single_port" {
  command = plan

  variables {
    port_range = "6379"
  }
}

run "valid_port_range" {
  command = plan

  variables {
    port_range = "8080-8090"
  }
}

run "invalid_port_range_format" {
  command = plan

  variables {
    port_range = "invalid"
  }

  expect_failures = [var.port_range]
}

# -----------------------------------------------------------------------------
# Session Affinity Validation Tests
# -----------------------------------------------------------------------------

run "valid_session_affinity_none" {
  command = plan

  variables {
    session_affinity = "NONE"
  }
}

run "valid_session_affinity_client_ip" {
  command = plan

  variables {
    session_affinity = "CLIENT_IP"
  }
}

run "invalid_session_affinity" {
  command = plan

  variables {
    session_affinity = "INVALID"
  }

  expect_failures = [var.session_affinity]
}

# -----------------------------------------------------------------------------
# Locality LB Policy Validation Tests
# -----------------------------------------------------------------------------

run "valid_lb_policy_round_robin" {
  command = plan

  variables {
    locality_lb_policy = "ROUND_ROBIN"
  }
}

run "valid_lb_policy_ring_hash" {
  command = plan

  variables {
    locality_lb_policy = "RING_HASH"
  }
}

run "invalid_lb_policy" {
  command = plan

  variables {
    locality_lb_policy = "INVALID_POLICY"
  }

  expect_failures = [var.locality_lb_policy]
}

# -----------------------------------------------------------------------------
# Balancing Mode Validation Tests
# -----------------------------------------------------------------------------

run "valid_balancing_mode_connection" {
  command = plan

  variables {
    balancing_mode = "CONNECTION"
  }
}

run "invalid_balancing_mode" {
  command = plan

  variables {
    balancing_mode = "INVALID"
  }

  expect_failures = [var.balancing_mode]
}

# -----------------------------------------------------------------------------
# Timeout Validation Tests
# -----------------------------------------------------------------------------

run "valid_timeout" {
  command = plan

  variables {
    timeout_sec = 60
  }
}

run "invalid_timeout_zero" {
  command = plan

  variables {
    timeout_sec = 0
  }

  expect_failures = [var.timeout_sec]
}

run "invalid_timeout_too_large" {
  command = plan

  variables {
    timeout_sec = 100000
  }

  expect_failures = [var.timeout_sec]
}

# -----------------------------------------------------------------------------
# Sample Rate Validation Tests
# -----------------------------------------------------------------------------

run "valid_sample_rate" {
  command = plan

  variables {
    log_config_sample_rate = 0.5
  }
}

run "invalid_sample_rate_negative" {
  command = plan

  variables {
    log_config_sample_rate = -0.1
  }

  expect_failures = [var.log_config_sample_rate]
}

run "invalid_sample_rate_too_high" {
  command = plan

  variables {
    log_config_sample_rate = 1.5
  }

  expect_failures = [var.log_config_sample_rate]
}

# -----------------------------------------------------------------------------
# Connection Limits Validation Tests
# -----------------------------------------------------------------------------

run "valid_max_connections" {
  command = plan

  variables {
    max_connections = 1000
  }
}

run "invalid_max_connections_zero" {
  command = plan

  variables {
    max_connections = 0
  }

  expect_failures = [var.max_connections]
}

run "invalid_max_connections_negative" {
  command = plan

  variables {
    max_connections = -100
  }

  expect_failures = [var.max_connections]
}

# -----------------------------------------------------------------------------
# IP Address Validation Tests
# -----------------------------------------------------------------------------

run "valid_ip_address_default" {
  command = plan

  variables {
    ip_address = "0.0.0.0"
  }
}

run "valid_ip_address_internal" {
  command = plan

  variables {
    ip_address = "10.100.1.5"
  }
}

run "invalid_ip_address_text" {
  command = plan

  variables {
    ip_address = "not-an-ip"
  }

  expect_failures = [var.ip_address]
}

run "invalid_ip_address_empty" {
  command = plan

  variables {
    ip_address = ""
  }

  expect_failures = [var.ip_address]
}
