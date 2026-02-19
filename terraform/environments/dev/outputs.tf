output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.compute.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.cluster_name
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${module.compute.alb_dns_name}:3000"
}
