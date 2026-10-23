# 초기 설정 가이드

현재 단계에서는 구조만 제공합니다. 아직 배포 가능한 구성이 아닙니다.

1. 계정명, 프로젝트명, DEV/PRD 환경 구분과 담당 팀을 확정합니다.
2. Terraform CLI와 AWS provider 버전을 결정하고 각 루트의 versions.tf에 선언합니다.
3. 배포 자격 증명과 대상 계정별 assume role을 준비합니다. 키를 저장소에 기록하지 않습니다.
4. 원격 state bucket과 잠금 구성을 사전 준비합니다.
5. templates/account 또는 templates/project를 새 배포 경로로 복사합니다.
   기존 예시 루트를 사용할 경우 해당 위치의 주석을 실제 구성으로 교체합니다.
6. backend.tf에 고유 key를 설정하고 provider.tf에 실제 역할·리전을 구성합니다.
7. 필요한 공통 모듈과 인터페이스를 구현하고 main.tf에서 호출합니다.
8. 태그 모듈 구현 후 tags.tf에서 기본 → 팀 → 배포 단위 순서로 병합합니다.
9. 완성된 배포 루트 안에서 아래 명령을 실행하고 plan을 검토합니다.

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan
```

각 루트의 `.terraform.lock.hcl`은 커밋합니다. state, plan, 실제 tfvars와 provider 바이너리는
커밋하지 않습니다. backend 설정 파일에도 자격 증명을 넣지 않습니다.

## 경로 예시

계정 배포 루트에서 네트워크 인터페이스를 호출할 때 상대 source는
`../../interfaces/vpc-three-tier`입니다.
루트에서 공통 VPC 모듈을 호출할 때는 `../../../tf-modules/network/vpc`,
기본 태그 모듈은 `../../../shared/tags/default`입니다.
아직 해당 모듈 구현이 없으므로 이 source 예시는 바로 실행하는 코드가 아닙니다.

EC2 초기 설정 스크립트와 Airgap 설정은 OS, 아키텍처, 버전 및 인증 방식 확정 후 작성합니다.
