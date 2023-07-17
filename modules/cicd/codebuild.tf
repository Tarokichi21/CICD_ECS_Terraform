# codebuild
resource "aws_codebuild_project" "codebuild" {
  name          = "${var.project_name}-${var.environment}-codebuild"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    s3_logs {
      status   = "ENABLED"
      location = "${var.project_name}-${var.environment}-artifact-store/buildlogs"
    }
    cloudwatch_logs {
      status = "DISABLED"
    }
  }
}

#codebuild_role
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-${var.environment}-codebuild_policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull"
        ]
        Resource : aws_codecommit_repository.codecommit.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          # "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.s3_artifact_store.arn,
          "${aws_s3_bucket.s3_artifact_store.arn}/*"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerRegistryFullAccess.arn
  role       = aws_iam_role.codebuild_role.name
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}