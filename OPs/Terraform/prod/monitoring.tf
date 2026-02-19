# EFS for persistent storage
resource "aws_efs_file_system" "monitoring" {
  encrypted = true

  tags = {
    Name        = "${var.environment}-monitoring-efs"
    Environment = var.environment
  }
}

resource "aws_efs_mount_target" "monitoring" {
  count           = 2
  file_system_id  = aws_efs_file_system.monitoring.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  vpc_id = aws_vpc.main.id

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
}

resource "aws_security_group" "monitoring" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Prometheus Task Definition
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.environment}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

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

# Loki Task Definition
resource "aws_ecs_task_definition" "loki" {
  family                   = "${var.environment}-loki"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

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

# Alloy Task Definition
resource "aws_ecs_task_definition" "alloy" {
  family                   = "${var.environment}-alloy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "alloy"
    image = "grafana/alloy:latest"
    portMappings = [{
      containerPort = 12345
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.monitoring.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "alloy"
      }
    }
  }])
}

# Grafana Task Definition
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.environment}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

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

# CloudWatch Log Group for Monitoring
resource "aws_cloudwatch_log_group" "monitoring" {
  name              = "/ecs/${var.environment}/monitoring"
  retention_in_days = var.log_retention_days
}

# ECS Services
resource "aws_ecs_service" "prometheus" {
  name            = "prometheus"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "loki" {
  name            = "loki"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "alloy" {
  name            = "alloy"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alloy.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
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

# ALB Target Group for Grafana
resource "aws_lb_target_group" "grafana" {
  name        = "${var.environment}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/api/health"
  }
}

# ALB Listener for Grafana
resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}
