data "github_repository" "target" {
  full_name = "${var.github_owner}/${var.github_repository}"
}

resource "github_actions_secret" "secret_name" {
  repository      = data.github_repository.target.name
  secret_name     = "AWS_SECRET_NAME"
  plaintext_value = aws_secretsmanager_secret.app_password.name
}

resource "github_actions_secret" "secret_region" {
  repository      = data.github_repository.target.name
  secret_name     = "AWS_REGION"
  plaintext_value = var.aws_region
}

resource "github_actions_secret" "app_password" {
  repository      = data.github_repository.target.name
  secret_name     = "APP_PASSWORD"
  plaintext_value = random_password.app_password.result
}
