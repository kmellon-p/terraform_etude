resource "random_password" "app_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "app_password" {
  name        = var.secret_name
  description = "etude-1 학습용으로 Terraform이 관리하는 애플리케이션 비밀번호"
}

resource "aws_secretsmanager_secret_version" "app_password" {
  secret_id = aws_secretsmanager_secret.app_password.id
  secret_string = jsonencode({
    password = random_password.app_password.result
  })
}
