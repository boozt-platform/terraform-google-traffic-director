# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "europe-west1"
}

variable "network" {
  description = "The VPC network name"
  type        = string
  default     = "default"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "redis"
}

variable "machine_type" {
  description = "Machine type for Redis instances"
  type        = string
  default     = "e2-medium"
}

variable "instance_count" {
  description = "Number of Redis instances"
  type        = number
  default     = 2
}

variable "environment" {
  description = "Environment name for labeling"
  type        = string
  default     = "dev"
}
