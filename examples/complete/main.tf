# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

# Complete Example: Redis Service Mesh with Traffic Director
#
# This example demonstrates:
# - Multiple backend services (read/write split)
# - Round-robin load balancing for reads
# - Sticky sessions (RING_HASH) for writes
# - Circuit breakers and outlier detection
# - Health checks with maintenance mode support

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0, < 7.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "google_project" "current" {}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# -----------------------------------------------------------------------------
# REQUIRED APIS
# -----------------------------------------------------------------------------

resource "google_project_service" "trafficdirector" {
  service            = "trafficdirector.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# HEALTH CHECK
# -----------------------------------------------------------------------------

resource "google_compute_health_check" "redis" {
  name = "${var.name_prefix}-health-check"

  http_health_check {
    port         = 6400
    request_path = "/health"
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# -----------------------------------------------------------------------------
# FIREWALL RULES
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "health_check" {
  name    = "${var.name_prefix}-allow-health-check"
  network = var.network

  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["${var.name_prefix}-server"]

  allow {
    protocol = "tcp"
    ports    = ["6379", "6380", "6400"]
  }
}

resource "google_compute_firewall" "internal" {
  name    = "${var.name_prefix}-allow-internal"
  network = var.network

  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["${var.name_prefix}-server"]

  allow {
    protocol = "tcp"
    ports    = ["6379", "6380"]
  }
}

# -----------------------------------------------------------------------------
# INSTANCE TEMPLATE & MIG
# -----------------------------------------------------------------------------

resource "google_compute_instance_template" "redis" {
  name_prefix  = "${var.name_prefix}-"
  machine_type = var.machine_type
  tags         = ["${var.name_prefix}-server"]

  disk {
    source_image = data.google_compute_image.ubuntu.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  network_interface {
    network = var.network
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "redis" {
  name               = "${var.name_prefix}-mig"
  base_instance_name = var.name_prefix
  region             = var.region
  target_size        = var.instance_count

  version {
    instance_template = google_compute_instance_template.redis.id
  }

  named_port {
    name = "redis-primary"
    port = 6379
  }

  named_port {
    name = "redis-replica"
    port = 6380
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.redis.id
    initial_delay_sec = 300
  }
}

# -----------------------------------------------------------------------------
# SERVICE MESH SERVICES
# -----------------------------------------------------------------------------

locals {
  services = {
    "${var.name_prefix}-read" = {
      port_name          = "redis-primary"
      port_range         = "6379"
      locality_lb_policy = "ROUND_ROBIN"
      session_affinity   = "NONE"
      timeout_sec        = 2
      circuit_breakers   = null
      outlier_detection  = null
    }
    "${var.name_prefix}-write" = {
      port_name          = "redis-primary"
      port_range         = "16379"
      locality_lb_policy = "RING_HASH"
      session_affinity   = "CLIENT_IP"
      timeout_sec        = 5
      circuit_breakers = {
        max_connections      = 1024
        max_pending_requests = 1000
        max_requests         = 2000
        max_retries          = 3
      }
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
  }
}

module "traffic_director" {
  for_each = local.services
  source   = "../../"

  project_id = var.project_id
  network    = var.network
  name       = each.key

  port_name  = each.value.port_name
  port_range = each.value.port_range

  health_check_id = google_compute_health_check.redis.id
  instance_groups = [google_compute_region_instance_group_manager.redis.instance_group]

  session_affinity                = each.value.session_affinity
  locality_lb_policy              = each.value.locality_lb_policy
  timeout_sec                     = each.value.timeout_sec
  connection_draining_timeout_sec = 10
  max_connections_per_instance    = 1000

  circuit_breakers  = each.value.circuit_breakers
  outlier_detection = each.value.outlier_detection

  labels = {
    environment = var.environment
    service     = "redis"
  }

  depends_on = [
    google_project_service.trafficdirector,
    google_project_service.compute,
  ]
}

# -----------------------------------------------------------------------------
# ENVOY CLIENT (for testing Traffic Director xDS configuration)
# -----------------------------------------------------------------------------

resource "google_compute_instance" "client" {
  name         = "${var.name_prefix}-client"
  machine_type = "e2-medium"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network = var.network
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["${var.name_prefix}-client"]

  metadata_startup_script = templatefile("${path.module}/client_startup.sh", {
    PROJECT_NUMBER = data.google_project.current.number
    NETWORK_NAME   = var.network
    ZONE           = "${var.region}-b"
    BS_ID_READ     = module.traffic_director["${var.name_prefix}-read"].backend_service.generated_id
    BS_ID_WRITE    = module.traffic_director["${var.name_prefix}-write"].backend_service.generated_id
  })

  depends_on = [module.traffic_director]
}
