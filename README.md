# Infrastructure as Code

This repository contains Terraform configurations for managing AWS infrastructure across multiple environments.

## Structure

```
terraform/
├── modules/           # Reusable Terraform modules
│   ├── networking/   # VPC, subnets, routing
│   ├── compute/      # ECS cluster, ALB, services
│   └── monitoring/   # Prometheus, Loki, Grafana
└── environments/     # Environment-specific configurations
    ├── dev/
    ├── staging/
    └── prod/
```

## Usage

### Deploy to Dev
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Staging
```bash
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
```

### Deploy to Production
```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## Modules

### Networking
- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Route tables and associations

### Compute
- ECS Fargate cluster
- Application Load Balancer
- ECS services and task definitions
- IAM roles and security groups

### Monitoring
- Prometheus for metrics
- Loki for logs
- Grafana for visualization
- EFS for persistent storage

## Environment Differences

| Environment | Tasks | CPU  | Memory | Log Retention | ALB Protection |
|-------------|-------|------|--------|---------------|----------------|
| Dev         | 1     | 256  | 512    | 7 days        | No             |
| Staging     | 2     | 256  | 512    | 14 days       | No             |
| Prod        | 3     | 512  | 1024   | 30 days       | Yes            |

## Documentation

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture information.
