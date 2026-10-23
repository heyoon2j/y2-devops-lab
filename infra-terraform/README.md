# infra-terraform

AWS 인프라를 도메인 및 배포 단위로 구분하는 Terraform 저장소입니다.
회사명과 실제 계정명 대신 중립적인 이름을 사용합니다.

- [아키텍처](ARCHITECTURE.md): 디렉터리 구조, 배포 경계, 모듈 의존 방향
- [초기 설정 가이드](docs/SETUP.md): 환경 확정 및 배포 루트 구성 절차
- `templates/`: 계정 및 프로젝트 배포 루트 복사 원본
- `tf-network/`, `tf-workload/`: 계정 기반 도메인
- `tf-identity/`: 프로젝트 기반 도메인
- `tf-modules/`: 공통 재사용 모듈
- `shared/tags/`: 공통 및 팀별 태그 모듈 예정 위치
- `tf-plugins/`: Airgap provider 미러 예정 위치

현재는 디렉터리와 문서, 주석만 있는 Terraform 파일로 구성된 골격입니다.
AWS 리소스, 원격 backend, provider, 태그 모듈은 아직 구현하지 않았습니다.
EC2 초기 설정 스크립트 `init-terraform-env.sh`는 실행 환경 요구사항 확정 후 추가합니다.
