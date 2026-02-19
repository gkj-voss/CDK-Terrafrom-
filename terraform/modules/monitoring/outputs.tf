output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${var.alb_arn}:3000"
}

output "efs_id" {
  value = aws_efs_file_system.monitoring.id
}
