# terraform_etude

## < etude - No.1 >

goal)
로컬에서 spring boot으로 aws-secret-manger를 사용해서 개발할 수 있다.
(로컬 docker환경에서는 안됨.)

work-flow)

1.  테라폼으로 secret manager 암호 주입
2.  테라폼으로 깃허브에 sercret 주입
3.  spring boot으로 aws SDK를 활용해 secret 비밀번호 확인해보기

environment)

1.  로컬에서 aws-cli 사용
2.  aws-cli는 terraform_user iam권한
    - arn:aws:iam::aws:policy/SecretsManagerReadWrite

## < etude - No.2 >

goal)
테라폼으로 간단한 아키텍쳐를 구성할 수 있다.
구성: - ECR (컨테이너 저장소) - EC2 (어플리케이션 서빙 장소, CD) - 빌드서버 (라즈베리 파이, CI, IAM Role 적용됨)

work-flow)

1.  테라폼으로 ECR, EC2 구성하기
2.  EC2 서버에 IAM Role 적용하기
3.  빌드서버 tail-scale로 보안 설정하기
4.  빌드 서버 self-hosting Agent (Runner) 연결하기
5.  git flow 작성

process)

git action(branch:main) -> 빌드서버 - 컨테이너 생성(buildx) -> 빌드서버 - ECR에 이미지 등록
-> EC2에서 최신버전을 Deploy (무중단X, 그냥 배포임. SSM으로하는게 맞는지는 모르겠음.)

environment)

1.  로컬에서 aws-cli 사용
2.  aws-cli는 terraform_user iam권한
    - arn:aws:iam::aws:policy/SecretsManagerReadWrite
    - arn:aws:iam::aws:policy/AmazonEC2FullAccess
    - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
    - arn:aws:iam::aws:policy/IAMFullAccess
    - arn:aws:iam::aws:policy/AmazonSSMFullAccess
3.  배포 서버(라즈베리파이 self-hosting)
    - runner
    - docker buildx
    - aws-cli

주의할 점)

- SSM으로 './delpoy.sh' 이런 명령어만 전송하고 구체적인 배포전력 등등...은 .sh파일로 구현하면 좋을듯?
- 지금처럼 빌드서버가 외부에 있을때는 aws-cli을 사용하기 때문에 tailscale, Runner를 사용하여 포트노출을 최소화하고 보안에 최소화 해야한다. (사실 보안은 저거 밖에 모르겠다.)
- 빌드 서버가 aws에 있으면 iam role을 적용하여 편하게 구현가능하다. 보안도 좋다.
  - aws에서 관리해 줌, 깃허브와 OIDC같은 연동 가능, iam키 생성과 노출에 걱정 ㄴㄴ.

## < etude - No.3 >

goal)
테라폼에서 git action으로 aws 인프라를 구축하고 관리할 수 있다.

work-flow)

1.  No.2를 git action으로 관리하기

process)

git action(branch:release ) -> terraform 주입 완료.

environment)

1.  깃허브와 aws를 OIDC 적용하기
2.  git release 브랜치에서 관리해보기
