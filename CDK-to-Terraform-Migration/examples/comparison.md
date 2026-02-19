# CDK to Terraform Comparison

## VPC

### CDK
```typescript
const vpc = new ec2.Vpc(this, 'MainVpc', {
  maxAzs: 2,
  natGateways: 1,
});
```

### Terraform
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}
```

## ECS Cluster

### CDK
```typescript
const cluster = new ecs.Cluster(this, 'MainCluster', {
  vpc: vpc,
});
```

### Terraform
```hcl
resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}
```

## Fargate Task Definition

### CDK
```typescript
const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDef', {
  cpu: 256,
  memoryLimitMiB: 512,
});

taskDefinition.addContainer('app', {
  image: ecs.ContainerImage.fromRegistry('nginx:latest'),
  portMappings: [{ containerPort: 80 }],
});
```

### Terraform
```hcl
resource "aws_ecs_task_definition" "main" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "app"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
  }])
}
```

## Application Load Balancer

### CDK
```typescript
const alb = new elbv2.ApplicationLoadBalancer(this, 'ALB', {
  vpc,
  internetFacing: true,
});
```

### Terraform
```hcl
resource "aws_lb" "main" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}
```

## Key Differences

1. **Abstraction Level**: CDK provides higher-level constructs, Terraform is more explicit
2. **State Management**: CDK uses CloudFormation, Terraform uses its own state
3. **Language**: CDK uses TypeScript/Python/etc, Terraform uses HCL
4. **Resource Naming**: CDK auto-generates names, Terraform requires explicit naming
5. **Dependencies**: CDK handles implicitly, Terraform uses explicit references
