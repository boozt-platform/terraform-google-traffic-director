# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

FROM jdxcode/mise:latest

# Install system dependencies for yamllint
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip && \
    pip3 install --no-cache-dir --break-system-packages yamllint && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy mise.toml to install tools during build
COPY mise.toml /tmp/mise.toml

# Install all tools from mise.toml
RUN cd /tmp && mise trust && mise install

# Clean up
RUN rm /tmp/mise.toml

WORKDIR /workspaces
