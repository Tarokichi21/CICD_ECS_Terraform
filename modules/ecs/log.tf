#CloudWatch_Logs
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = "/ecs/${var.project_name}/${var.environment}/fargate"
  retention_in_days = 30
}
