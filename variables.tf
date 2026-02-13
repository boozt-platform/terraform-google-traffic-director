# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

variable "project_id" {
  description = "The ID of the GCP project in which to provision resources."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "network" {
  description = "The VPC network name or self_link to which resources will be attached."
  type        = string

  validation {
    condition     = length(var.network) > 0
    error_message = "Network must not be empty."
  }
}

variable "name" {
  description = "The base name for resources. Suffixes will be added (e.g., '-bs' for backend service, '-proxy' for TCP proxy)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name)) && length(var.name) <= 50
    error_message = "Name must start with a letter, contain only lowercase letters, numbers, and hyphens, end with a letter or number, and be at most 50 characters."
  }
}

variable "port_name" {
  description = "The named port on the instance group (must match a named_port defined on the MIG)."
  type        = string

  validation {
    condition     = length(var.port_name) > 0
    error_message = "Port name must not be empty."
  }
}

variable "port_range" {
  description = "The port range for the forwarding rule (e.g., '6379' or '8080-8090')."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+(-[0-9]+)?$", var.port_range))
    error_message = "Port range must be a single port (e.g., '6379') or a range (e.g., '8080-8090')."
  }
}

variable "health_check_id" {
  description = "The ID (self_link) of an externally created health check resource."
  type        = string

  validation {
    condition     = length(var.health_check_id) > 0
    error_message = "Health check ID must not be empty."
  }
}

variable "instance_groups" {
  description = "A list of instance group URLs (self_links) to be used as backends."
  type        = list(string)

  validation {
    condition     = length(var.instance_groups) > 0
    error_message = "At least one instance group must be provided."
  }
}

variable "session_affinity" {
  description = "The session affinity for the backend service. Use 'CLIENT_IP' with 'RING_HASH' for sticky sessions."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "CLIENT_IP", "CLIENT_IP_PORT_PROTO", "CLIENT_IP_PROTO", "GENERATED_COOKIE", "HEADER_FIELD", "HTTP_COOKIE"], var.session_affinity)
    error_message = "Session affinity must be one of: NONE, CLIENT_IP, CLIENT_IP_PORT_PROTO, CLIENT_IP_PROTO, GENERATED_COOKIE, HEADER_FIELD, HTTP_COOKIE."
  }
}

variable "locality_lb_policy" {
  description = "The load balancing policy. Use 'ROUND_ROBIN' for even distribution or 'RING_HASH' for consistent hashing (sticky sessions)."
  type        = string
  default     = "ROUND_ROBIN"

  validation {
    condition     = contains(["ROUND_ROBIN", "LEAST_REQUEST", "RING_HASH", "RANDOM", "ORIGINAL_DESTINATION", "MAGLEV"], var.locality_lb_policy)
    error_message = "Locality LB policy must be one of: ROUND_ROBIN, LEAST_REQUEST, RING_HASH, RANDOM, ORIGINAL_DESTINATION, MAGLEV."
  }
}

variable "circuit_breakers" {
  description = "Circuit breaker configuration for the backend service."
  type = object({
    max_connections      = optional(number)
    max_pending_requests = optional(number)
    max_requests         = optional(number)
    max_retries          = optional(number)
  })
  default = null
}

variable "outlier_detection" {
  description = "Outlier detection configuration for automatic ejection of unhealthy backends."
  type = object({
    consecutive_errors   = optional(number)
    max_ejection_percent = optional(number)
    interval = optional(object({
      seconds = number
      nanos   = optional(number)
    }))
    base_ejection_time = optional(object({
      seconds = number
      nanos   = optional(number)
    }))
  })
  default = null
}

variable "log_config_enable" {
  description = "Whether to enable logging for the backend service."
  type        = bool
  default     = false
}

variable "log_config_sample_rate" {
  description = "The sampling rate for logging (0.0 to 1.0). Only applies when log_config_enable is true."
  type        = number
  default     = 1.0

  validation {
    condition     = var.log_config_sample_rate >= 0.0 && var.log_config_sample_rate <= 1.0
    error_message = "Log sample rate must be between 0.0 and 1.0."
  }
}

variable "timeout_sec" {
  description = "Backend service timeout in seconds. How long to wait for a backend to respond."
  type        = number
  default     = 30

  validation {
    condition     = var.timeout_sec >= 1 && var.timeout_sec <= 86400
    error_message = "Timeout must be between 1 and 86400 seconds."
  }
}

variable "connection_draining_timeout_sec" {
  description = "Time in seconds to wait for connections to drain when removing a backend."
  type        = number
  default     = 0

  validation {
    condition     = var.connection_draining_timeout_sec >= 0 && var.connection_draining_timeout_sec <= 3600
    error_message = "Connection draining timeout must be between 0 and 3600 seconds."
  }
}

variable "balancing_mode" {
  description = "The balancing mode for backends. Use 'CONNECTION' for TCP traffic."
  type        = string
  default     = "CONNECTION"

  validation {
    condition     = contains(["UTILIZATION", "RATE", "CONNECTION"], var.balancing_mode)
    error_message = "Balancing mode must be one of: UTILIZATION, RATE, CONNECTION."
  }
}

variable "labels" {
  description = "Labels to apply to the forwarding rule resource."
  type        = map(string)
  default     = {}
}

variable "max_connections_per_instance" {
  description = "Maximum number of simultaneous connections per backend instance."
  type        = number
  default     = null

  validation {
    condition     = try(var.max_connections_per_instance > 0, var.max_connections_per_instance == null)
    error_message = "Max connections per instance must be a positive number."
  }
}

variable "create_forwarding_rule" {
  description = "Whether to create the forwarding rule and TCP proxy. Set to false if forwarding rule is not required."
  type        = bool
  default     = true
}

variable "ip_address" {
  description = "The IP address for the forwarding rule. Use '0.0.0.0' for the default mesh-wide listener, or a different address (e.g., '10.0.0.0') to avoid port conflicts when multiple backend services share the same port."
  type        = string
  default     = "0.0.0.0"
}

variable "max_connections" {
  description = "Maximum number of simultaneous connections for the entire backend service."
  type        = number
  default     = null

  validation {
    condition     = try(var.max_connections > 0, var.max_connections == null)
    error_message = "Max connections must be a positive number."
  }
}
