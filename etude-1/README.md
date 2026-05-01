# etude-1

Terraform으로 AWS Secrets Manager에 비밀번호를 생성하고, 같은 값을 GitHub Actions secret으로도 주입한 뒤, Spring Boot에서 AWS SDK로 조회하는 흐름을 학습한다.

## 사전 준비

- 로컬 `aws-cli`에 'SecretsManagerReadWrite'권한을 가진 iam 계정  `terraform_user`이 설정되어 있어야 한다.
- GitHub provider 인증을 위해 `repo` 스코프가 있는 PAT를 환경변수로 노출한다.

```bash
export GITHUB_TOKEN=ghp_xxx
```

## 적용

```bash
cd etude-1
cp terraform.tfvars.example terraform.tfvars   # github_owner / github_repository 값을 채운다
terraform init
terraform plan
terraform apply
```

apply 후 다음이 만들어진다.

- AWS Secrets Manager 시크릿 (`var.secret_name`, JSON: `{"password": "..."}`)
- GitHub Actions 시크릿 3개: `AWS_SECRET_NAME`, `AWS_REGION`, `APP_PASSWORD`

## Spring Boot에서 조회 (참고)

`software.amazon.awssdk:secretsmanager` 의존성을 추가하고 다음과 같이 호출한다.

디펜던시 'implementation 'io.awspring.cloud:spring-cloud-starter-aws-secrets-manager:4.0.1'는 수동으로 추가해야한다. 버전에 맞게 수정해서 사용하도록 하자.

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
terraform destroy
```
