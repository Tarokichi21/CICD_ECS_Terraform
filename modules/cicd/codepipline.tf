# codepipline
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project_name}-${var.environment}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.s3_artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        BranchName           = "master"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
        RepositoryName       = aws_codecommit_repository.codecommit.repository_name
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {

        ClusterName = "${var.ecs_cluster_name}"
        ServiceName = "${var.ecs_service_name}"
      }
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-${var.environment}-codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        # "s3:GetObjectVersion",
        # "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.s3_artifact_store.arn,
          "${aws_s3_bucket.s3_artifact_store.arn}/*"
        ]
      },
      # 追加
      { Effect = "Allow"
        Action = [
          "codecommit:GetRepository",
          "codecommit:GetBranch",
          "codecommit:GetCommit"
        ]
        Resource : aws_codecommit_repository.codecommit.arn
      },

      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource : aws_codebuild_project.codebuild.arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
          # "${var.ecs_cluster_arn}",
          # "${var.ecs_service_id}",
          # "arn:aws:ecs:ap-northeast-1:410362506341:task-definition/${var.ecs_task_definition_family}:*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        "Condition" : {
          "StringEqualsIfExists" : {
            "iam:PassedToService" : [
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# Cloudwatch Event Rule
resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name = "${var.project_name}-${var.environment}-cloudwatch_event_rule"

  event_pattern = templatefile("../modules/cicd/codepipeline_event_pattern.json", {
    codecommit_arn : aws_codecommit_repository.codecommit.arn
  })
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_rule" {
  rule     = aws_cloudwatch_event_rule.cloudwatch_event_rule.name
  arn      = aws_codepipeline.codepipeline.arn
  role_arn = aws_iam_role.event_bridge_codepipeline.arn
}

resource "aws_iam_role" "event_bridge_codepipeline" {
  name               = "${var.project_name}-${var.environment}-event-bridge-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.event_bridge_assume_role.json
  inline_policy {
    name   = "codepipeline"
    policy = data.aws_iam_policy_document.event_bridge_codepipeline.json
  }
}

data "aws_iam_policy_document" "event_bridge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "event_bridge_codepipeline" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = ["${aws_codepipeline.codepipeline.arn}"]
  }
}