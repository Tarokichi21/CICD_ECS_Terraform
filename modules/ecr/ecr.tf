#ECR
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.project_name}-${var.environment}-ecr-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}