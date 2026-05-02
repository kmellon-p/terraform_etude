# etude-2

Terraform으로 ECR + EC2 + 빌드서버용 IAM을 한 번에 띄우고, 라즈베리파이(빌드서버, self-hosted runner)에서 컨테이너를 빌드해 ECR에 push, EC2가 SSM RunCommand로 새 이미지를 pull 받아 배포하는 흐름을 학습한다. etude-1에서 만든 Secrets Manager 시크릿/GitHub secrets는 그대로 이어서 사용한다.

## goal

- 테라폼으로 간단한 아키텍처를 구성할 수 있다.
- 구성: ECR(컨테이너 저장소) / EC2(어플리케이션 서빙, CD) / 빌드서버(라즈베리파이, CI, IAM 권한 적용)

## work-flow

1. 테라폼으로 ECR, EC2 구성하기
2. EC2에 IAM Role 적용하기 (ECR pull, Secrets Manager read, SSM)
3. 빌드서버 Tailscale로 보안 설정하기 *(인프라 외 작업, 라즈베리파이 OS에서 직접 설정)*
4. 빌드서버에 GitHub self-hosted runner 등록 *(라즈베리파이에서 직접 설정)*
5. git flow 작성 (`.github/workflows/deploy.yml`)

## process

```
git push (branch: relase)
  -> 빌드서버(self-hosted runner)에서 buildx로 컨테이너 빌드
  -> 빌드서버에서 ECR로 push
  -> SSM SendCommand로 EC2에 deploy 지시
  -> EC2에서 docker pull + docker run (무중단 X, 그냥 재기동)
```

## environment

1. 로컬에서 `aws-cli` 사용
2. `aws-cli`는 `terraform_user` (모든 권한 보유 IAM 사용자)
3. GitHub provider 인증을 위해 `repo` 스코프 PAT를 환경변수로 노출

```bash
export GITHUB_TOKEN=ghp_xxx
```

## 디렉터리 구조

```
etude-2/
├── README.md
├── .github/workflows/deploy.yml   # self-hosted runner 워크플로우
├── terraform/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── secrets_manager.tf         # (etude-1에서 이어옴) Secrets Manager 시크릿
│   ├── github_secrets.tf          # (etude-1에서 이어옴) GitHub Actions secret 주입
│   │                              # --- work-flow 1) 테라폼으로 ECR, EC2 구성 ---
│   ├── network.tf                 # default VPC 조회 + Security Group
│   ├── ecr.tf                     # ECR repository + lifecycle
│   ├── ec2.tf                     # EC2 + user_data (docker pull/run)
│   │                              # --- work-flow 2) EC2에 IAM Role 적용 ---
│   │                              # (ec2.tf 내부에서 IAM Role / Instance Profile 같이 정의)
│   │                              # --- work-flow 5) git flow용 빌드서버 자격증명 ---
│   ├── build_server_iam.tf        # 빌드서버용 IAM User + access key + GitHub secret 주입
│   └── outputs.tf
└── springboot/
    ├── Dockerfile
    ├── build.gradle
    └── src/...                    # /, /health, /secret 엔드포인트
```

## 적용

```bash
cd etude-2/terraform
cp terraform.tfvars.example terraform.tfvars   # github_owner / github_repository 채움
terraform init
terraform plan
terraform apply
```

apply 후 만들어지는 것:

- AWS Secrets Manager 시크릿 (`var.secret_name`, JSON: `{"password": "..."}`)
- ECR 리포지토리 (`<project>-app`)
- EC2 인스턴스 (Amazon Linux 2023, Docker 설치, ECR pull/run user_data)
- IAM Role (EC2용): ECR ReadOnly + SSM Managed + 시크릿 read
- IAM User (라즈베리파이 빌드서버용) + access key
- GitHub Actions secrets:
  - etude-1 그대로: `AWS_SECRET_NAME`, `AWS_REGION`, `APP_PASSWORD`
  - etude-2 추가: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `ECR_REGISTRY`, `ECR_REPOSITORY`, `EC2_INSTANCE_ID`

## 빌드서버(라즈베리파이) 셋업

테라폼이 닿지 않는 부분이라 라즈베리파이 OS에 직접 작업한다.

1. Tailscale 가입 후 라즈베리파이에 데몬 설치, ACL은 본인 디바이스만 통신 가능하도록 설정
2. Docker, buildx 설치 (`docker buildx version` 확인)
3. GitHub repo > Settings > Actions > Runners 에서 새 self-hosted runner 토큰 발급, 라즈베리파이에서 등록
   - 라벨: `self-hosted, linux, raspberry` (워크플로우의 `runs-on` 과 맞춰야 함)
4. runner 서비스로 등록 (`./svc.sh install && ./svc.sh start`)

## 배포 흐름

`release`에 push 되어 `etude-2/springboot/**` 가 변경되면 `.github/workflows/deploy.yml` 이 동작한다.

1. self-hosted runner가 체크아웃
2. `aws-actions/configure-aws-credentials` 로 빌드서버 IAM User 자격 증명 주입
3. `docker buildx` 로 `linux/amd64` 이미지 빌드 *(빌드서버는 arm64지만 EC2는 x86이라 크로스 빌드)*
4. ECR로 `:latest` 와 `:<commit-sha>` 두 태그로 push
5. `aws ssm send-command` 로 EC2에서 다음을 실행시킴:

   ```
   docker login (ECR)
   docker pull <new-image>
   docker rm -f app
   docker run -d --name app --restart=always -p 8080:8080 \
     -e AWS_REGION=... -e AWS_SECRET_NAME=... <new-image>
   ```

## 동작 확인

```bash
# 1) 앱이 떴는지
curl "$(terraform -chdir=terraform output -raw app_url)/health"

# 2) Secrets Manager 값이 EC2 IAM Role을 통해 잘 읽히는지
curl "$(terraform -chdir=terraform output -raw app_url)/secret"
```

## 정리

```bash
cd etude-2/terraform
terraform destroy
```

## 참고

- EC2는 default VPC의 첫 번째 subnet에 띄운다. 학습용이라 단순화함.
- 보안 그룹은 `app_port`(8080) 만 0.0.0.0/0에 열려 있고, SSH는 `ec2_key_name` 을 줄 때만 22가 열린다.
- key pair 없이 EC2에 들어가고 싶으면 `aws ssm start-session --target <EC2_INSTANCE_ID>` (IAM 권한 이미 부여됨).
- Spring Boot 컨테이너는 EC2 IAM Role의 자격 증명 체인으로 Secrets Manager에 접근한다. access key 환경변수 안 쓴다.
- etude-3에서는 위 인프라를 GitHub Actions + OIDC로 관리하는 단계로 넘어간다.
