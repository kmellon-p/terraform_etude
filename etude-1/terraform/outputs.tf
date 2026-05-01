output "secret_arn" {
  description = "생성된 Secrets Manager 시크릿의 ARN"
  value       = aws_secretsmanager_secret.app_password.arn
}

output "secret_name" {
  description = "Spring Boot가 조회할 시크릿 이름"
  value       = aws_secretsmanager_secret.app_password.name
}
