terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "ecs/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
  tags        = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  environment                = var.environment
  aws_region                 = var.aws_region
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  private_subnet_ids         = module.networking.private_subnet_ids
  cluster_name               = var.cluster_name
  container_image            = var.container_image
  desired_count              = var.desired_count
  task_cpu                   = var.task_cpu
  task_memory                = var.task_memory
  log_retention_days         = var.log_retention_days
  enable_deletion_protection = true
  tags                       = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  environment                = var.environment
  aws_region                 = var.aws_region
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  cluster_id                 = module.compute.cluster_id
  alb_arn                    = module.compute.alb_dns_name
  alb_security_group_id      = module.compute.alb_security_group_id
  ecs_task_execution_role_arn = module.compute.ecs_task_execution_role_arn
  ecs_task_role_arn          = module.compute.ecs_task_role_arn
  log_retention_days         = var.log_retention_days
  tags                       = local.common_tags
}
