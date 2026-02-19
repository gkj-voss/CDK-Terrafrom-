resource "aws_efs_file_system" "monitoring" {
  encrypted = true

  tags = merge(var.tags, {
    Name = "${var.environment}-monitoring-efs"
  })
}

resource "aws_efs_mount_target" "monitoring" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.monitoring.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-efs-sg"
  })
}

resource "aws_security_group" "monitoring" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 12345
    to_port     = 12345
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-monitoring-sg"
  })
}

resource "aws_cloudwatch_log_group" "monitoring" {
  name              = "/ecs/${var.environment}/monitoring"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.environment}-monitoring-logs"
  })
}

# Prometheus
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.environment}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "prometheus"
    image = "prom/prometheus:latest"
    portMappings = [{
      containerPort = 9090
      protocol      = "tcp"
    }]
    mountPoints = [{
      sourceVolume  = "prometheus-data"
      containerPath = "/prometheus"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "prometheus"
      }
    }
  }])

  volume {
    name = "prometheus-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.monitoring.id
      root_directory = "/prometheus"
    }
  }
}

resource "aws_ecs_service" "prometheus" {
  name            = "prometheus"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }
}

# Loki
resource "aws_ecs_task_definition" "loki" {
  family                   = "${var.environment}-loki"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "loki"
    image = "grafana/loki:latest"
    portMappings = [{
      containerPort = 3100
      protocol      = "tcp"
    }]
    mountPoints = [{
      sourceVolume  = "loki-data"
      containerPath = "/loki"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "loki"
      }
    }
  }])

  volume {
    name = "loki-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.monitoring.id
      root_directory = "/loki"
    }
  }
}

resource "aws_ecs_service" "loki" {
  name            = "loki"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }
}

# Grafana
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.environment}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "grafana"
    image = "grafana/grafana:latest"
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    environment = [
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin" }
    ]
    mountPoints = [{
      sourceVolume  = "grafana-data"
      containerPath = "/var/lib/grafana"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "grafana"
      }
    }
  }])

  volume {
    name = "grafana-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.monitoring.id
      root_directory = "/grafana"
    }
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.environment}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/api/health"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-grafana-tg"
  })
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = var.alb_arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.grafana]
}
