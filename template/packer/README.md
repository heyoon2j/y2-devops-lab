```
packer/
├── templates/            # Packer 템플릿(JSON/HCL) 파일 저장
│   ├── base-image.pkr.hcl  # 기본 이미지 생성 템플릿
│   ├── app-image.pkr.hcl   # 애플리케이션 포함된 이미지 템플릿
│   ├── variables.pkrvars.hcl  # 변수 정의 파일
│   └── ubuntu/           # OS별로 폴더 구분 가능
│       ├── ubuntu-20.pkr.hcl
│       └── ubuntu-22.pkr.hcl
│
├── scripts/              # 이미지 빌드 후 실행할 스크립트
│   ├── install_docker.sh
│   ├── configure_app.sh
│   ├── hardening.sh
│   └── cleanup.sh
│
├── ansible/              # Ansible 플레이북(선택 사항)
│   ├── playbook.yml
│   ├── roles/
│   └── inventory
│
├── modules/              # Packer 모듈(공유 가능한 설정)
│   ├── aws.pkr.hcl       # AWS 관련 빌더 설정
│   ├── gcp.pkr.hcl       # GCP 관련 빌더 설정
│   ├── azure.pkr.hcl     # Azure 관련 빌더 설정
│   └── common.pkr.hcl    # 공통 설정 파일
│
├── output/               # 빌드된 아티팩트(AMI ID, 이미지 정보 등 저장)
│   ├── ami-manifest.json
│   ├── docker-image.tar
│   ├── metadata.log
│   └── packer.log
│
├── packer.auto.pkrvars.hcl  # 기본 변수(자동 로드됨)
├── packer.hcl             # Packer 기본 설정 파일
├── README.md              # 프로젝트 설명 파일
└── .gitignore             # Git 제외할 파일 설정

```