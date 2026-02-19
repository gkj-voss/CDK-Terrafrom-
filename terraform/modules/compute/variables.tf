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

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
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
  default     = 2
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = string
  default     = "512"
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 7
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
