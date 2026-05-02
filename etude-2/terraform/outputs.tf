output "secret_arn" {
  description = "생성된 Secrets Manager 시크릿의 ARN"
  value       = aws_secretsmanager_secret.app_password.arn
}

output "secret_name" {
  description = "Spring Boot가 조회할 시크릿 이름"
  value       = aws_secretsmanager_secret.app_password.name
}

output "ecr_repository_url" {
  description = "docker push 할 ECR URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ec2_public_ip" {
  description = "앱 서빙 EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "ec2_instance_id" {
  description = "EC2 인스턴스 ID (SSM 배포에 사용)"
  value       = aws_instance.app.id
}

output "app_url" {
  description = "Spring Boot 앱 URL"
  value       = "http://${aws_instance.app.public_ip}:${var.app_port}"
}

output "builder_access_key_id" {
  description = "라즈베리파이 빌드서버에서 사용할 access key id (GitHub secret으로도 주입됨)"
  value       = aws_iam_access_key.builder.id
}

output "builder_secret_access_key" {
  description = "라즈베리파이 빌드서버에서 사용할 secret access key"
  value       = aws_iam_access_key.builder.secret
  sensitive   = true
}
