variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
