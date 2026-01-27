#!/bin/bash
# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

# Envoy Client Startup Script for Traffic Director Testing
# This script installs Envoy and configures it to connect to Traffic Director

set -e

# Variables passed from Terraform
PROJECT_NUMBER="${PROJECT_NUMBER}"
NETWORK_NAME="${NETWORK_NAME}"
ZONE="${ZONE}"
BS_ID_READ="${BS_ID_READ}"
BS_ID_WRITE="${BS_ID_WRITE}"

# Install dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release redis-tools

# Install Envoy
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/getenvoy.list
apt-get update
apt-get install -y getenvoy-envoy

# Create Envoy bootstrap configuration for Traffic Director
cat > /etc/envoy/bootstrap.yaml << EOF
node:
  id: "envoy-client-$(hostname)"
  cluster: "envoy-client"
  locality:
    zone: "${ZONE}"
  metadata:
    TRAFFICDIRECTOR_NETWORK_NAME: "${NETWORK_NAME}"
    TRAFFICDIRECTOR_GCP_PROJECT_NUMBER: "${PROJECT_NUMBER}"

dynamic_resources:
  lds_config:
    resource_api_version: V3
    ads: {}
  cds_config:
    resource_api_version: V3
    ads: {}
  ads_config:
    api_type: GRPC
    transport_api_version: V3
    grpc_services:
    - google_grpc:
        target_uri: trafficdirector.googleapis.com:443
        stat_prefix: trafficdirector
        channel_credentials:
          ssl_credentials:
            root_certs:
              filename: /etc/ssl/certs/ca-certificates.crt
        call_credentials:
          google_compute_engine: {}

static_resources:
  clusters:
  - name: cloud-internal-istio:cloud_mp_${PROJECT_NUMBER}_${BS_ID_READ}
    type: EDS
    eds_cluster_config:
      eds_config:
        resource_api_version: V3
        ads: {}
    connect_timeout: 5s
    lb_policy: ROUND_ROBIN
  - name: cloud-internal-istio:cloud_mp_${PROJECT_NUMBER}_${BS_ID_WRITE}
    type: EDS
    eds_cluster_config:
      eds_config:
        resource_api_version: V3
        ads: {}
    connect_timeout: 5s
    lb_policy: RING_HASH
  listeners:
  - name: redis-read
    address:
      socket_address:
        address: 127.0.0.1
        port_value: 6379
    filter_chains:
    - filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: redis_read
          cluster: cloud-internal-istio:cloud_mp_${PROJECT_NUMBER}_${BS_ID_READ}
  - name: redis-write
    address:
      socket_address:
        address: 127.0.0.1
        port_value: 16379
    filter_chains:
    - filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: redis_write
          cluster: cloud-internal-istio:cloud_mp_${PROJECT_NUMBER}_${BS_ID_WRITE}

admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
EOF

# Create systemd service for Envoy
cat > /etc/systemd/system/envoy.service << 'EOF'
[Unit]
Description=Envoy Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/envoy -c /etc/envoy/bootstrap.yaml --log-level info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start Envoy
systemctl daemon-reload
systemctl enable envoy
systemctl start envoy

echo "Envoy client setup complete. Test with:"
echo "  redis-cli -h 127.0.0.1 -p 6379 PING    # read endpoint"
echo "  redis-cli -h 127.0.0.1 -p 16379 PING   # write endpoint"
