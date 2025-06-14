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
- templates: 빌드 정의 (builders, provisioners, source) 등을 정의하는 핵심 Packer 템플릿 파일을 모아둔 디렉토리
    - ./shared: 공통 로직 (빌드 전략, 프로비저닝 방식 등)
    - ./local: 클라우드별 빌더 정의
- modules: OS별 설치 스크립트 - 실제 인스턴스에서 실행될 설정들
- scripts: 유틸리티 실행 스크립트 (Packer 자체와 무관한 Helper 도구의 성격 스크립트 / ex> Packer 실행)
- variables: 공통적으로 사용되는 변수들


사용자 실행 (scripts/entrypoint.sh 또는 직접 명령어 실행)
→ template.pkr.hcl 로딩 (aws/, gcp/)
→ templates/shared/ 및 templates/local/ 템플릿 merge
→ variables/common.pkrvars.hcl 로 변수 주입
→ modules/<os>/install.sh 실행
→ 빌드 완료 후 AMI 또는 GCP 이미지 생성


```
packer/
├── aws/
│   └── template.pkr.hcl
├── gcp/
│   └── template.pkr.hcl
├── templates/
│   ├── shared/
│   │   └── build_common.pkr.hcl
│   └── local/
│       ├── aws.pkr.hcl
│       └── gcp.pkr.hcl
├── modules/
│   ├── rocky9/
│   │   └── install.sh
│   └── ubuntu22/
│       └── install.sh
├── variables/
│   └── common.pkrvars.hcl
└── scripts/
    └── entrypoint.sh
```
