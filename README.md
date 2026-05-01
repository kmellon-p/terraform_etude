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
2.  aws-cli는 terraform_user( iam권한: SecretsManagerReadWrite )

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
2.  aws-cli는 terraform_user(모든 권한을 가짐)

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
