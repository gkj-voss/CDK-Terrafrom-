# Quick Reference

## Directory Structure

```
terraform/
├── modules/              # Reusable infrastructure components
│   ├── networking/      # VPC, subnets, NAT, IGW
│   ├── compute/         # ECS, ALB, IAM roles
│   └── monitoring/      # Prometheus, Loki, Grafana, EFS
└── environments/        # Environment-specific configs
    ├── dev/            # Development (1 task, 7d logs)
    ├── staging/        # Staging (2 tasks, 14d logs)
    └── prod/           # Production (3 tasks, 30d logs, ALB protection)
```

## Common Commands

### Initialize
```bash
cd terraform/environments/<env>
terraform init
```

### Plan Changes
```bash
terraform plan
```

### Apply Changes
```bash
terraform apply
```

### Destroy
```bash
terraform destroy
```

## Module Outputs

### Networking
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`

### Compute
- `cluster_id`
- `cluster_name`
- `alb_dns_name`
- `alb_security_group_id`
- `ecs_task_execution_role_arn`
- `ecs_task_role_arn`

### Monitoring
- `grafana_url`
- `efs_id`

## Customization

Edit environment-specific values in:
```
terraform/environments/<env>/variables.tf
```

Edit module defaults in:
```
terraform/modules/<module>/variables.tf
```

## State Management

Each environment has its own state file:
- Dev: `s3://bucket/ecs/dev/terraform.tfstate`
- Staging: `s3://bucket/ecs/staging/terraform.tfstate`
- Prod: `s3://bucket/ecs/prod/terraform.tfstate`

Update bucket name in each environment's `main.tf`.
