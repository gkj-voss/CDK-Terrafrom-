# ECS Infrastructure - Complete Architecture Design

## Table of Contents
1. [Architecture Diagram](#architecture-diagram)
2. [Network Flow](#network-flow)
3. [Deployment Flow](#deployment-flow)
4. [Monitoring Flow](#monitoring-flow)
5. [AWS Services](#aws-services)
6. [Provisioning Steps](#provisioning-steps)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS CLOUD (VPC)                                    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    PUBLIC SUBNETS (2 AZs)                          │    │
│  │                                                                    │    │
│  │  ┌──────────────────────────────────────────────────────────┐    │    │
│  │  │  Application Load Balancer (ALB)                         │    │    │
│  │  │  - Port 80 (App)                                         │    │    │
│  │  │  - Port 3000 (Grafana)                                   │    │    │
│  │  │  - Health Checks                                         │    │    │
│  │  │  - Target Groups                                         │    │    │
│  │  └────────────────────┬─────────────────────────────────────┘    │    │
│  │                       │                                           │    │
│  │  ┌────────────────────┴─────────────────────────────────────┐    │    │
│  │  │  Internet Gateway                                        │    │    │
│  │  └──────────────────────────────────────────────────────────┘    │    │
│  │                                                                    │    │
│  │  ┌──────────────────────────────────────────────────────────┐    │    │
│  │  │  NAT Gateway + Elastic IP                                │    │    │
│  │  └────────────────────┬─────────────────────────────────────┘    │    │
│  └─────────────────────────┼──────────────────────────────────────────┘    │
│                            │                                                │
│  ┌─────────────────────────┼──────────────────────────────────────────┐    │
│  │              PRIVATE SUBNETS (2 AZs)                             │    │
│  │                       │                                           │    │
│  │  ┌────────────────────▼─────────────────────────────────────┐    │    │
│  │  │  ECS FARGATE CLUSTER                                     │    │    │
│  │  │                                                          │    │    │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │    │    │
│  │  │  │ App Service  │  │ App Service  │  │ App Service  │  │    │    │
│  │  │  │ (Task 1)     │  │ (Task 2)     │  │ (Task 3)     │  │    │    │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘  │    │    │
│  │  │                                                          │    │    │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │    │    │
│  │  │  │ Prometheus   │  │ Grafana      │  │ Loki         │  │    │    │
│  │  │  │ (Metrics)    │  │ (Dashboard)  │  │ (Logs)       │  │    │    │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘  │    │    │
│  │  │                                                          │    │    │
│  │  │  ┌──────────────┐  ┌──────────────┐                    │    │    │
│  │  │  │ Alloy        │  │ Alertmanager │                    │    │    │
│  │  │  │ (Collector)  │  │ (Alerts)     │                    │    │    │
│  │  │  └──────────────┘  └──────────────┘                    │    │    │
│  │  └──────────────────────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  STORAGE & PERSISTENCE                                             │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │    │
│  │  │ EFS          │  │ ECR          │  │ S3 Buckets   │           │    │
│  │  │ (Monitoring) │  │ (Images)     │  │ (Backups)    │           │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  SECURITY & IAM                                                    │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │    │
│  │  │ Security     │  │ IAM Roles    │  │ KMS Keys     │           │    │
│  │  │ Groups       │  │ (ECS Tasks)  │  │ (Encryption) │           │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  MONITORING & LOGGING                                              │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │    │
│  │  │ CloudWatch   │  │ AWS Backup   │  │ SNS Topics   │           │    │
│  │  │ Logs         │  │ (EFS)        │  │ (Alerts)     │           │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
         │                              │                              │
         ▼                              ▼                              ▼
  ┌─────────────┐              ┌──────────────┐              ┌──────────────┐
  │   Slack     │              │  DynamoDB    │              │  GitHub      │
  │  (Alerts)   │              │  (TF Lock)   │              │  (CI/CD)     │
  └─────────────┘              └──────────────┘              └──────────────┘
```

---

## Network Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    REQUEST FLOW                                 │
└─────────────────────────────────────────────────────────────────┘

1. User Request
   │
   ▼
2. Route 53 (DNS) [Optional]
   │
   ▼
3. Application Load Balancer (Public Subnet)
   │
   ├─► Port 80  → App Target Group
   │              │
   │              ▼
   │           ECS Tasks (Private Subnet)
   │              │
   │              ▼
   │           Application Container
   │
   └─► Port 3000 → Grafana Target Group
                  │
                  ▼
               Grafana Container (Private Subnet)

4. Response Path (Reverse)
   │
   ▼
5. User receives response


┌─────────────────────────────────────────────────────────────────┐
│                  OUTBOUND FLOW                                  │
└─────────────────────────────────────────────────────────────────┘

ECS Tasks (Private Subnet)
   │
   ▼
NAT Gateway (Public Subnet)
   │
   ▼
Internet Gateway
   │
   ▼
Internet (Pull images, API calls, etc.)


┌─────────────────────────────────────────────────────────────────┐
│                  MONITORING FLOW                                │
└─────────────────────────────────────────────────────────────────┘

Application Containers
   │
   ├─► Metrics → Alloy → Prometheus → Grafana
   │
   └─► Logs → CloudWatch Logs → Loki → Grafana

Prometheus Alerts
   │
   ▼
Alertmanager
   │
   ▼
Slack Webhook
```

---

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  CI/CD PIPELINE                                 │
└─────────────────────────────────────────────────────────────────┘

Developer
   │
   ▼
Git Push to GitHub
   │
   ▼
GitHub Actions Triggered
   │
   ├─► Branch: develop
   │   │
   │   ├─► Terraform Plan (dev)
   │   └─► Manual Review
   │
   └─► Branch: main
       │
       ├─► Terraform Plan (dev/staging/prod)
       │
       ├─► Terraform Apply (Auto)
       │   │
       │   ├─► Infrastructure Changes
       │   │   │
       │   │   ├─► VPC/Subnets
       │   │   ├─► Security Groups
       │   │   ├─► ALB/Target Groups
       │   │   ├─► ECS Cluster
       │   │   └─► Monitoring Stack
       │   │
       │   └─► Application Deployment
       │       │
       │       ├─► Build Docker Image
       │       ├─► Push to ECR
       │       ├─► Update Task Definition
       │       └─► Update ECS Service
       │
       └─► Slack Notification
           │
           ├─► Success ✓
           └─► Failure ✗


┌─────────────────────────────────────────────────────────────────┐
│              ROLLBACK FLOW                                      │
└─────────────────────────────────────────────────────────────────┘

Issue Detected
   │
   ▼
Run Rollback Script
   │
   ├─► Option 1: Previous Task Definition
   │   │
   │   └─► aws ecs update-service --task-definition previous
   │
   ├─► Option 2: Previous Terraform State
   │   │
   │   └─► terraform state pull backup.tfstate
   │
   └─► Option 3: Restore from Backup
       │
       └─► AWS Backup restore EFS
```


---

## AWS Services Used

### Compute
- **ECS Fargate**: Serverless container orchestration
- **ECR**: Container image registry

### Networking
- **VPC**: Isolated network environment
- **Subnets**: Public (2 AZs) and Private (2 AZs)
- **Internet Gateway**: Internet access for public subnets
- **NAT Gateway**: Outbound internet for private subnets
- **Application Load Balancer**: Layer 7 load balancing
- **Route Tables**: Traffic routing configuration

### Storage
- **EFS**: Persistent storage for monitoring data
- **S3**: Backup storage and Terraform state
- **ECR**: Container image storage

### Security
- **Security Groups**: Firewall rules
- **IAM Roles**: Task execution and runtime permissions
- **KMS**: Encryption keys (optional)

### Monitoring & Logging
- **CloudWatch Logs**: Centralized logging
- **CloudWatch Alarms**: Infrastructure monitoring
- **SNS**: Alert notifications
- **AWS Backup**: Automated EFS backups

### Database
- **DynamoDB**: Terraform state locking

---

## Provisioning Steps

### Phase 1: Prerequisites (Manual)

```bash
# 1. Create S3 bucket for Terraform state
aws s3 mb s3://my-terraform-state-bucket
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# 2. Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# 3. Create Slack webhook
# Visit: https://api.slack.com/messaging/webhooks
# Save webhook URL for later

# 4. Configure GitHub Secrets
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# SLACK_WEBHOOK_URL
```

### Phase 2: Environment Setup

```bash
# 1. Clone repository
git clone <repository-url>
cd Sample

# 2. Update configuration
# Edit OPs/Terraform/{env}/terraform.tfvars
# - Update slack_webhook_url
# - Update container_image (if custom)
# - Adjust resource sizing

# 3. Update backend configuration
# Edit OPs/Terraform/{env}/backend.tf
# - Update bucket name
# - Update region if needed
```

### Phase 3: Infrastructure Deployment

```bash
# Deploy Dev Environment
cd OPs/Terraform/dev
terraform init -backend-config="key=ecs/dev/terraform.tfstate"
terraform plan
terraform apply

# Deploy Staging Environment
cd ../staging
terraform init -backend-config="key=ecs/staging/terraform.tfstate"
terraform plan
terraform apply

# Deploy Production Environment
cd ../prod
terraform init -backend-config="key=ecs/prod/terraform.tfstate"
terraform plan
terraform apply
```

### Phase 4: Post-Deployment Configuration

```bash
# 1. Get ALB DNS name
terraform output alb_dns_name

# 2. Access Grafana
# URL: http://<alb-dns>:3000
# Default credentials: admin/admin

# 3. Configure Grafana data sources
# - Add Prometheus: http://prometheus:9090
# - Add Loki: http://loki:3100

# 4. Import Grafana dashboards
# - ECS metrics dashboard
# - Application logs dashboard

# 5. Verify alerts
# - Check Alertmanager: http://<internal-ip>:9093
# - Test Slack notifications

# 6. Configure DNS (Optional)
# - Create Route 53 hosted zone
# - Point domain to ALB DNS
# - Update ALB listener for HTTPS
```

### Phase 5: Application Deployment

```bash
# 1. Build and push Docker image
docker build -t my-app:latest .
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag my-app:latest <account>.dkr.ecr.us-east-1.amazonaws.com/dev-app:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/dev-app:latest

# 2. Update task definition
# Edit OPs/Terraform/{env}/terraform.tfvars
# Update container_image with new ECR image

# 3. Apply changes
terraform apply

# 4. Verify deployment
aws ecs describe-services \
  --cluster dev-main-cluster \
  --services app-service
```

---

## Resource Sizing by Environment

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| **ECS Tasks** | 1 | 2 | 3 |
| **Task CPU** | 256 | 512 | 1024 |
| **Task Memory** | 512 MB | 1 GB | 2 GB |
| **NAT Gateways** | 1 | 1 | 2 |
| **Log Retention** | 7 days | 14 days | 30 days |
| **Backup Retention** | 7 days | 14 days | 30 days |

---

## Cost Estimation

### Monthly Costs (Approximate)

**Dev Environment:**
- ECS Fargate: $15-25
- ALB: $20-25
- NAT Gateway: $35-45
- EFS: $5-10
- CloudWatch: $5-10
- **Total: ~$80-115/month**

**Staging Environment:**
- ECS Fargate: $30-50
- ALB: $20-25
- NAT Gateway: $35-45
- EFS: $10-15
- CloudWatch: $10-15
- **Total: ~$105-150/month**

**Production Environment:**
- ECS Fargate: $60-100
- ALB: $25-35
- NAT Gateway: $70-90 (2 gateways)
- EFS: $15-25
- CloudWatch: $15-25
- **Total: ~$185-275/month**

**Note:** Costs vary based on traffic, data transfer, and actual usage.

---

## Security Best Practices

1. **Network Security**
   - Private subnets for all compute resources
   - Security groups with least privilege
   - No direct internet access for containers

2. **IAM Security**
   - Separate roles for task execution and runtime
   - Minimal permissions per role
   - No hardcoded credentials

3. **Data Security**
   - Encryption at rest (EFS, S3)
   - Encryption in transit (TLS)
   - Secrets in AWS Secrets Manager (recommended)

4. **Monitoring Security**
   - CloudWatch Logs encryption
   - Alert on security events
   - Regular security audits

---

## Maintenance Tasks

### Daily
- Monitor Slack alerts
- Check Grafana dashboards
- Review application logs

### Weekly
- Review CloudWatch metrics
- Check backup status
- Update container images

### Monthly
- Review and optimize costs
- Update Terraform modules
- Security patches
- Disaster recovery drill

### Quarterly
- Architecture review
- Capacity planning
- Update documentation
- Team training

---

## Troubleshooting Guide

### Issue: Tasks not starting
```bash
# Check task logs
aws ecs describe-tasks --cluster <cluster> --tasks <task-id>
aws logs tail /ecs/<env>/main-cluster --follow
```

### Issue: ALB health checks failing
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>
# Verify security group rules
# Check container health endpoint
```

### Issue: High costs
```bash
# Review NAT Gateway usage
# Check CloudWatch Logs retention
# Optimize ECS task sizing
# Review data transfer costs
```

### Issue: Terraform state locked
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>
# Or delete DynamoDB lock item
```

---

## Support & Documentation

- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws
- **AWS ECS Docs**: https://docs.aws.amazon.com/ecs/
- **Prometheus Docs**: https://prometheus.io/docs/
- **Grafana Docs**: https://grafana.com/docs/

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024 | Initial architecture |
| 1.1 | 2024 | Added monitoring stack |
| 1.2 | 2024 | Added backup strategy |
