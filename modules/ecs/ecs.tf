#Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"
}

#TaskDefinition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "html-sample-fargate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      "name" : "html-sample-fargate",
      "image" : "${var.ecr_repo_url}",
      "essential" : true,
      "portMappings" : [
        {
          containerPort : 80,
          hostPort : 80,
          protocol = "tcp"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "ap-northeast-1",
          "awslogs-stream-prefix" : "html-sample-fargate",
          "awslogs-group" : "${aws_cloudwatch_log_group.cloudwatch_log_group.name}"
        }
      },
      "memoryReservation" : 128,
      "cpu" : 256
    }
  ])
}

#Service
resource "aws_ecs_service" "ecs_service" {
  name                               = "html-sample-fargate"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  launch_type                        = "FARGATE"
  task_definition                    = data.aws_ecs_task_definition.task_definition.arn
  desired_count                      = 3
  force_new_deployment               = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_name   = "html-sample-fargate"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_c.id]
    security_groups  = [aws_security_group.ecs_fargate_sg.id]
    assign_public_ip = false
  }
}

data "aws_ecs_task_definition" "task_definition" {
  task_definition = aws_ecs_task_definition.ecs_task_definition.family
}

#Security_Group_ECS
resource "aws_security_group" "ecs_fargate_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${var.project_name}-html-sample-fargate-sg"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
