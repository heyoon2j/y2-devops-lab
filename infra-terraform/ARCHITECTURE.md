# Terraform 아키텍처

저장소 이름은 `infra-terraform`을 사용합니다. 예시 계정명은 추후 실제 이름으로 교체합니다.
working directory 하나가 독립된 배포 및 state 관리 단위입니다.

```text
infra-terraform/
├── README.md
├── ARCHITECTURE.md
├── docs/
│   └── SETUP.md
├── templates/
│   ├── account/                  # 계정 배포 루트 복사 원본
│   └── project/                  # 프로젝트 배포 루트 복사 원본
├── tf-network/
│   ├── accounts/
│   │   ├── network-dev/
│   │   └── network-prd/           # PRD 계정별 추가 가능
│   └── interfaces/
│       └── vpc-three-tier/
├── tf-workload/
│   ├── accounts/
│   │   └── workload-prd/          # 계정별 추가 가능
│   └── interfaces/
│       └── platform-eks/
├── tf-identity/
│   └── projects/
│       ├── iam-roles/
│       └── sso-config/
├── tf-modules/
│   ├── iam-role/
│   ├── eks-nodegroup/
│   └── network/
│       ├── security-group/
│       ├── vpc/
│       └── subnet/
├── shared/
│   └── tags/
│       ├── README.md
│       ├── default/
│       ├── cloud/
│       ├── data/
│       └── identity/
└── tf-plugins/
```
`init-terraform-env.sh`는 EC2 OS 및 설치·인증 방식 확정 후 추가할 예정입니다.
`interfaces` 명칭은 모든 도메인에서 복수형으로 통일합니다.

## 배포 루트
Account 패턴: `tf-{domain}/accounts/{account-name}/`
Project 패턴: `tf-{domain}/projects/{project-id}/`

두 패턴 모두 다음 파일을 사용합니다.

| 파일 | 책임 |
| --- | --- |
| backend.tf | 원격 state 저장 위치와 잠금 설정 |
| provider.tf | AWS 리전, assume role, 필요한 provider alias |
| versions.tf | Terraform 및 provider 버전 제약 |
| tags.tf | 공통·팀·배포 단위 태그 조합 |
| main.tf | 인터페이스 및 공통 모듈 호출 |
| network.tf / eks.tf / iam.tf / sso.tf | 필요한 도메인 구성 |
| README.md | 배포 대상, 선행 조건, 운영 절차 |

`main.tf`와 도메인 파일은 같은 Terraform 모듈이며 실행 순서나 격리 경계가 아닙니다.

## State 경계

동일 bucket 내에서도 모든 배포 루트는 서로 다른 key를 사용합니다.

- Account: `account/{account-id}/{domain}/terraform.tfstate`
- Project: `project/{domain}/{project-id}/terraform.tfstate`

원본 예시의 `account/{account-id}/terraform.tfstate`에 domain을 추가해,
동일 AWS 계정에서 network와 workload를 운영할 때 state가 충돌하지 않도록 합니다.
프로젝트도 domain을 포함해 이름 충돌을 방지합니다.
DEV/PRD가 같은 계정과 같은 domain을 공유한다면 key에 환경 경로를 추가해야 합니다.
backend는 일반 Terraform 변수나 locals를 참조할 수 없으므로 실제 값 또는 별도 backend 설정으로 전달합니다.
state bucket과 잠금 기반 구성은 사전에 준비하며 이 골격에서는 생성하지 않습니다.

계정 루트는 해당 계정의 역할을 assume합니다. 프로젝트가 여러 계정을 다루면
루트에서 명시적인 provider alias를 선언하고 각 모듈에 전달합니다.
프로젝트 하나의 여러 계정 리소스는 하나의 state와 배포 생명주기를 공유합니다.
독립된 배포가 필요하면 프로젝트를 분리합니다.

## 모듈 계층

```text
accounts / projects (배포 루트)
  ├── interfaces (도메인 조합 모듈) → tf-modules
  ├── tf-modules (직접 호출도 가능)
  └── shared/tags (태그 조합)
```

backend 및 계정별 provider 설정은 배포 루트만 소유합니다.
재사용 모듈은 provider 요구사항을 선언하고 호출자로부터 provider 구성을 받습니다.
공통 모듈은 accounts, projects, interfaces를 참조하지 않습니다.
도메인 내부 중복 modules 디렉터리는 만들지 않고, 도메인 전용 조합은 interfaces에 둡니다.
저장소 루트와 templates, interfaces, 공통 모듈 디렉터리는 배포 대상이 아닙니다.

## 현재 구현 범위

Terraform 파일은 주석만 있는 자리표시자입니다. 실제 리소스, 입력/출력, provider 버전,
원격 state, 태그 모듈, EC2 초기 설정 및 Airgap 설치는 후속 구현 대상입니다.
