variable "aws_region" {
  description = "Secrets Manager가 생성될 AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "secret_name" {
  description = "AWS Secrets Manager에 저장될 시크릿 이름"
  type        = string
  default     = "etude-1/app-password"
}

variable "github_owner" {
  description = "GitHub 사용자 또는 organization 이름"
  type        = string
}

variable "github_repository" {
  description = "GitHub 시크릿을 주입할 레포지토리 이름"
  type        = string
}
