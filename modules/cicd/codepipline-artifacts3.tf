resource "aws_s3_bucket" "s3_artifact_store" {
  bucket = "${var.project_name}-${var.environment}-artifact-store"
}