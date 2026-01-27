#!/bin/bash
# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT
set -e

# Install Redis
apt-get update && apt-get install -y redis-server python3

# Stop default Redis service
systemctl stop redis-server
systemctl disable redis-server

# Create directories
mkdir -p /var/lib/redis/6379 /var/lib/redis/6380 /var/run/redis
chown -R redis:redis /var/lib/redis /var/run/redis

# Configure Redis instances
for PORT in 6379 6380; do
  cat > /etc/redis/redis_${PORT}.conf <<EOF
port ${PORT}
daemonize yes
pidfile /var/run/redis/redis_${PORT}.pid
logfile /var/log/redis_${PORT}.log
dir /var/lib/redis/${PORT}
bind 0.0.0.0
protected-mode no
maxclients 10000
EOF
  chown redis:redis /etc/redis/redis_${PORT}.conf
done

# Start Redis instances
sudo -u redis redis-server /etc/redis/redis_6379.conf
sudo -u redis redis-server /etc/redis/redis_6380.conf

# Health check server with maintenance mode support
cat > /usr/local/bin/healthcheck.py <<'PYTHON'
import http.server
import subprocess
import sys

PORT = 6400

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress logging

    def do_GET(self):
        if self.path != '/health':
            self.send_response(404)
            self.end_headers()
            return

        try:
            # Check Redis is responding
            subprocess.check_call(
                ["redis-cli", "-p", "6379", "ping"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            subprocess.check_call(
                ["redis-cli", "-p", "6380", "ping"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

            # Check for maintenance mode (unhealthy key)
            result = subprocess.run(
                ["redis-cli", "-p", "6379", "exists", "unhealthy"],
                capture_output=True,
                text=True
            )
            if "1" in result.stdout:
                raise Exception("Maintenance mode enabled")

            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f"Unhealthy: {e}".encode())

if __name__ == "__main__":
    server = http.server.HTTPServer(('0.0.0.0', PORT), HealthHandler)
    print(f"Health check server running on port {PORT}")
    server.serve_forever()
PYTHON

# Start health check server
nohup python3 /usr/local/bin/healthcheck.py > /var/log/healthcheck.log 2>&1 &

echo "Redis setup complete"
