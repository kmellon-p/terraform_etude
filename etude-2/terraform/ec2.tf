data "aws_caller_identity" "current" {}

# --- IAM Role for EC2 ---

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_app" {
  name               = "${var.project_name}-ec2-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# ECR pull
resource "aws_iam_role_policy_attachment" "ec2_ecr_readonly" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM Session Manager로 접근하기 위함 (key pair 없이도 들어갈 수 있음)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Spring Boot에서 etude-1 시크릿을 그대로 읽기 위함
data "aws_iam_policy_document" "ec2_secret_read" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.app_password.arn]
  }
}

resource "aws_iam_policy" "ec2_secret_read" {
  name   = "${var.project_name}-ec2-secret-read"
  policy = data.aws_iam_policy_document.ec2_secret_read.json
}

resource "aws_iam_role_policy_attachment" "ec2_secret_read" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = aws_iam_policy.ec2_secret_read.arn
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.project_name}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name
}

# --- EC2 instance ---

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  ecr_image    = "${local.ecr_registry}/${aws_ecr_repository.app.name}:${var.container_image_tag}"

  user_data = <<-EOT
    #!/bin/bash
    set -eux

    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user

    # ECR 로그인 + 최신 이미지 pull/run
    aws ecr get-login-password --region ${var.aws_region} \
      | docker login --username AWS --password-stdin ${local.ecr_registry} || true

    docker pull ${local.ecr_image} || echo "image not pushed yet, skipping initial run"

    if docker image inspect ${local.ecr_image} >/dev/null 2>&1; then
      docker rm -f app || true
      docker run -d --name app --restart=always \
        -p ${var.app_port}:${var.app_port} \
        -e AWS_REGION=${var.aws_region} \
        -e AWS_SECRET_NAME=${var.secret_name} \
        ${local.ecr_image}
    fi
  EOT
}

resource "aws_instance" "app" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_app.name
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name
  user_data                   = local.user_data

  tags = {
    Name = "${var.project_name}-app"
  }
}
