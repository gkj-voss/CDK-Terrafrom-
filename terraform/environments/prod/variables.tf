variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "main-cluster"
}

variable "container_image" {
  description = "Docker image"
  type        = string
  default     = "nginx:latest"
}

variable "desired_count" {
  description = "Number of tasks"
  type        = number
  default     = 3
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = string
  default     = "1024"
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 30
}
