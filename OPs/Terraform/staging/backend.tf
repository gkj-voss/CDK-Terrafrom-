terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "ecs/${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
