# Complete Example

This example creates a complete Traffic Director setup for Redis with:

- Managed Instance Group (MIG) with 2 Redis instances
- Health check with maintenance mode support
- Read service with round-robin load balancing
- Write service with sticky sessions (RING_HASH)
- Circuit breakers and outlier detection for the write service

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan -var="project_id=your-project-id"

# Apply
terraform apply -var="project_id=your-project-id"
```

## Testing

After deployment, you can test the setup by:

1. SSH into a client VM with Envoy configured
2. Run Redis commands through Envoy:

```bash
# Test read (round-robin)
for i in {1..10}; do redis-cli -p 6379 GET server_id; done

# Test write (sticky)
for i in {1..10}; do redis-cli -p 16379 GET server_id; done
```

## Maintenance Mode

To put a Redis instance in maintenance mode:

```bash
# Enable maintenance (server will be ejected from pool)
redis-cli -p 6379 SET unhealthy 1

# Disable maintenance (server will rejoin pool)
redis-cli -p 6379 DEL unhealthy
```

## Clean Up

```bash
terraform destroy -var="project_id=your-project-id"
```
