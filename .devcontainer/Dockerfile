# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

FROM jdxcode/mise:latest

# Install system dependencies and Google Cloud SDK
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip \
        curl \
        gnupg \
        apt-transport-https \
        ca-certificates && \
    pip3 install --no-cache-dir --break-system-packages yamllint checkov && \
    # Install Google Cloud SDK
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy mise.toml to install tools during build
COPY mise.toml /tmp/mise.toml

# Install all tools from mise.toml
RUN cd /tmp && mise trust && mise install

# Clean up
RUN rm /tmp/mise.toml

WORKDIR /workspaces
