# 라즈베리파이(빌드서버)에서 사용할 IAM User.
# - ECR push/pull
# - EC2에 SSM run-command 보내서 새 이미지로 재배포
# 라즈베리파이는 AWS 외부에 있으니 IAM Role 대신 access key를 쓴다.

resource "aws_iam_user" "builder" {
  name = "${var.project_name}-builder"
}

data "aws_iam_policy_document" "builder" {
  # ECR auth token (전 리소스 대상)
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # 우리 레포에만 push/pull
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:ListImages",
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  # EC2에 새 이미지 deploy 시킬 때 SSM RunCommand 사용
  statement {
    effect = "Allow"
    actions = [
      "ssm:SendCommand",
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "builder" {
  name   = "${var.project_name}-builder-policy"
  policy = data.aws_iam_policy_document.builder.json
}

resource "aws_iam_user_policy_attachment" "builder" {
  user       = aws_iam_user.builder.name
  policy_arn = aws_iam_policy.builder.arn
}

resource "aws_iam_access_key" "builder" {
  user = aws_iam_user.builder.name
}

# --- 빌드서버용 access key를 GitHub Actions secret으로도 자동 주입 ---

resource "github_actions_secret" "builder_access_key_id" {
  repository      = data.github_repository.target.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.builder.id
}

resource "github_actions_secret" "builder_secret_access_key" {
  repository      = data.github_repository.target.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.builder.secret
}

resource "github_actions_secret" "ecr_repository" {
  repository      = data.github_repository.target.name
  secret_name     = "ECR_REPOSITORY"
  plaintext_value = aws_ecr_repository.app.name
}

resource "github_actions_secret" "ecr_registry" {
  repository      = data.github_repository.target.name
  secret_name     = "ECR_REGISTRY"
  plaintext_value = local.ecr_registry
}

resource "github_actions_secret" "ec2_instance_id" {
  repository      = data.github_repository.target.name
  secret_name     = "EC2_INSTANCE_ID"
  plaintext_value = aws_instance.app.id
}
