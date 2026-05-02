variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름에 들어갈 prefix"
  type        = string
  default     = "etude2"
}

# --- etude-1에서 이어받음 ---

variable "secret_name" {
  description = "AWS Secrets Manager에 저장될 시크릿 이름"
  type        = string
  default     = "etude-2/app-password"
}

variable "github_owner" {
  description = "GitHub 사용자 또는 organization 이름"
  type        = string
}

variable "github_repository" {
  description = "GitHub 시크릿을 주입할 레포지토리 이름"
  type        = string
}

# --- etude-2에서 추가 ---

variable "ec2_ami_id" {
  description = "EC2가 사용할 AMI ID. SSM agent 사전 설치된 AL2023 표준 AMI 권장."
  type        = string
  # ap-northeast-2, AL2023 kernel-6.1, x86_64
  default = "ami-087e08db3e40f7429"
}

variable "ec2_instance_type" {
  description = "어플리케이션을 서빙할 EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "EC2에 SSH로 접근할 때 사용할 기존 key pair 이름. null이면 SSM Session Manager로만 접근."
  type        = string
  default     = null
}

variable "ssh_ingress_cidr" {
  description = "EC2 22번 포트로 접근을 허용할 CIDR. ec2_key_name이 null이면 무시됨."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Spring Boot 앱이 듣는 포트"
  type        = number
  default     = 8080
}

variable "container_image_tag" {
  description = "EC2에서 pull/run 할 이미지 태그. 빌드서버에서 push 한 태그와 맞춰야 함."
  type        = string
  default     = "latest"
}
