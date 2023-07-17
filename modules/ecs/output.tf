output "endpoint" {
  value = "endpoint: http://${aws_lb.alb.dns_name}"
}


output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.ecs_cluster.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "ecs_service_id" {
  value = aws_ecs_service.ecs_service.id
}

output "ecs_task_definition_family" {
  value = aws_ecs_task_definition.ecs_task_definition.family
}

output "alb_tg_name" {
  value = aws_lb_target_group.alb_tg.name
}