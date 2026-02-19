#!/bin/bash

# CDK to Terraform Migration Import Script
# Replace placeholder values with actual resource IDs

set -e

echo "Starting CDK to Terraform migration import..."

# VPC
terraform import aws_vpc.main vpc-xxxxx

# Subnets
terraform import 'aws_subnet.public[0]' subnet-xxxxx
terraform import 'aws_subnet.public[1]' subnet-xxxxx
terraform import 'aws_subnet.private[0]' subnet-xxxxx
terraform import 'aws_subnet.private[1]' subnet-xxxxx

# Internet Gateway
terraform import aws_internet_gateway.main igw-xxxxx

# NAT Gateway
terraform import aws_nat_gateway.main nat-xxxxx
terraform import aws_eip.nat eipalloc-xxxxx

# Route Tables
terraform import aws_route_table.public rtb-xxxxx
terraform import aws_route_table.private rtb-xxxxx

# Security Groups
terraform import aws_security_group.alb sg-xxxxx
terraform import aws_security_group.ecs_tasks sg-xxxxx

# ALB
terraform import aws_lb.main arn:aws:elasticloadbalancing:region:account:loadbalancer/app/name/xxxxx
terraform import aws_lb_target_group.main arn:aws:elasticloadbalancing:region:account:targetgroup/name/xxxxx
terraform import aws_lb_listener.main arn:aws:elasticloadbalancing:region:account:listener/app/name/xxxxx/xxxxx

# ECS
terraform import aws_ecs_cluster.main cluster-name
terraform import aws_ecs_task_definition.main family:revision
terraform import aws_ecs_service.main cluster-name/service-name

# IAM Roles
terraform import aws_iam_role.ecs_task_execution role-name
terraform import aws_iam_role.ecs_task role-name

# CloudWatch
terraform import aws_cloudwatch_log_group.ecs /ecs/cluster-name

echo "Import completed. Run 'terraform plan' to verify."
