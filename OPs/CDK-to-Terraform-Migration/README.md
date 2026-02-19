# AWS CDK to Terraform Migration Guide

## Overview
This folder contains resources and guides for migrating AWS CDK infrastructure to Terraform.

## Migration Strategy

### 1. Assessment Phase
- Inventory existing CDK stacks
- Document resource dependencies
- Identify stateful resources

### 2. Preparation
```bash
# Export CDK stack to CloudFormation
cdk synth > cdk-stack.yaml

# Use cdktf for conversion (optional)
npm install -g cdktf-cli
```

### 3. Migration Approaches

#### Option A: Manual Migration
1. Analyze CDK constructs
2. Write equivalent Terraform resources
3. Import existing resources using `terraform import`

#### Option B: Using cdktf
```bash
cdktf init --template=typescript --local
# Convert CDK code to CDKTF
# Generate Terraform JSON
cdktf synth
```

### 4. Import Existing Resources
```bash
# Import VPC
terraform import aws_vpc.main vpc-xxxxx

# Import ECS Cluster
terraform import aws_ecs_cluster.main cluster-name

# Import ALB
terraform import aws_lb.main arn:aws:elasticloadbalancing:...
```

## Migration Checklist

- [ ] Document all CDK resources
- [ ] Create Terraform equivalents
- [ ] Set up remote state backend
- [ ] Import existing resources
- [ ] Validate with `terraform plan`
- [ ] Test in dev environment
- [ ] Update CI/CD pipelines
- [ ] Migrate staging
- [ ] Migrate production
- [ ] Decommission CDK stacks

## Resource Mapping

| CDK Construct | Terraform Resource |
|---------------|-------------------|
| ec2.Vpc | aws_vpc |
| ecs.Cluster | aws_ecs_cluster |
| ecs.FargateService | aws_ecs_service |
| elbv2.ApplicationLoadBalancer | aws_lb |
| iam.Role | aws_iam_role |
| logs.LogGroup | aws_cloudwatch_log_group |

## Tools

- **cdktf**: CDK for Terraform
- **terraform import**: Import existing resources
- **terraformer**: Generate Terraform from existing infrastructure
- **former2**: Browser-based IaC generator

## Best Practices

1. Migrate one environment at a time
2. Use `terraform import` for stateful resources
3. Maintain parallel stacks during transition
4. Test thoroughly before cutover
5. Keep rollback plan ready

## Example Migration

See `examples/` folder for:
- CDK stack samples
- Equivalent Terraform code
- Import scripts
