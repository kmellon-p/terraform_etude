# etude-1

Terraform으로 AWS Secrets Manager에 애플리케이션 비밀번호를 생성하고, 동일한 값을 GitHub Actions 시크릿으로도 주입한 뒤, Spring Boot에서 AWS SDK로 조회하는 흐름을 학습한다.

## 구성

```
etude-1/
├── terraform/    # AWS Secrets Manager + GitHub Actions secret 프로비저닝
└── springboot/   # 시크릿을 조회하는 Spring Boot 예제
```

## 사전 준비

- 로컬 `aws-cli`에 `SecretsManagerReadWrite` 권한을 가진 IAM 사용자(`terraform_user`)가 프로필로 설정되어 있어야 한다.
- GitHub provider 인증을 위해 `repo` 스코프 PAT를 환경변수로 노출한다.

```bash
export GITHUB_TOKEN=ghp_xxx
```

## Terraform 적용

```bash
cd etude-1/terraform
cp terraform.tfvars.example terraform.tfvars   # github_owner / github_repository 값 채우기
terraform init
terraform plan
terraform apply
```

apply 후 다음이 생성된다.

- AWS Secrets Manager 시크릿 — 이름: `var.secret_name`, 값: `{"password": "..."}` (24자 랜덤)
- GitHub Actions 시크릿 3개
  - `AWS_SECRET_NAME` — 시크릿 이름
  - `AWS_REGION` — 시크릿이 위치한 리전
  - `APP_PASSWORD` — 생성된 평문 비밀번호

### 주요 변수

| 변수                | 기본값                 | 설명                            |
| ------------------- | ---------------------- | ------------------------------- |
| `aws_region`        | `ap-northeast-2`       | Secrets Manager 리전            |
| `secret_name`       | `etude-1/app-password` | 시크릿 이름                     |
| `github_owner`      | (필수)                 | GitHub 사용자 또는 organization |
| `github_repository` | (필수)                 | 시크릿을 주입할 레포지토리      |

## Spring Boot에서 조회

`software.amazon.awssdk:secretsmanager` 의존성을 추가한다. Spring Cloud AWS 스타터를 함께 쓰려면 다음을 수동으로 추가하고, 사용 중인 Spring Boot 버전에 맞게 조정한다.

```groovy
implementation 'io.awspring.cloud:spring-cloud-starter-aws-secrets-manager:4.0.1'
```

AWS SDK 직접 호출 예시:

```java
SecretsManagerClient client = SecretsManagerClient.builder()
    .region(Region.of(System.getenv("AWS_REGION")))
    .build();

String json = client.getSecretValue(
    GetSecretValueRequest.builder()
        .secretId(System.getenv("AWS_SECRET_NAME"))
        .build()
).secretString();
// json -> {"password": "..."} 파싱하여 사용
```

기본 자격증명 체인을 사용하므로 로컬에서는 `aws-cli` 프로필이, GitHub Actions에서는 OIDC 또는 access key 시크릿이 자격증명 소스가 된다.

## 정리

```bash
cd etude-1/terraform
terraform destroy
```

`recovery_window_in_days = 0`으로 설정되어 있어 destroy 시 시크릿이 즉시 삭제된다.
