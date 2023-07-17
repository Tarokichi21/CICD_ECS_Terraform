#codecommit
resource "aws_codecommit_repository" "codecommit" {
  repository_name = "${var.project_name}-${var.environment}-repository"
}