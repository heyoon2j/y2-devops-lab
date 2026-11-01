# Terraform 작업 설정 설계

`infra-terraform` 개발 작업에 필요한 설정을 정의합니다. 모듈, interfaces 및 배포 루트별
작업 범위를 구분하기 위한 설계이며 실행 가능한 설정 파일이나 확정된 스키마는 아닙니다.

## 작업 설정 항목

| 항목 | 내용 |
| --- | --- |
| 식별 | 설정 버전, 대상 저장소와 디렉터리, 기준 commit |
| 개발 규칙 | 아키텍처, 코딩 규칙, 정책 문서와 충돌 처리 기준 |
| 근거 범위 | 포함·제외 경로, 필수 문서, 파일·컨텍스트 크기 제한 |
| 변경 범위 | 수정 가능한 경로, 보호 경로, 변경량 제한 |
| 실행 환경 | Terraform·provider 버전의 근거, 설치 선행 조건과 실행 위치 |
| 검증 | 검사별 argv, cwd 선택 방식, 선행 조건, timeout, 필수 여부 |
| 권한 | 네트워크, 인증 정보, 배포·외부 쓰기 승인 정책 |
| 완료 기준 | 필수 검사, 산출물, 미확정 요구사항 처리 |

규칙 문서는 신뢰하는 설정으로 관리하고 검색된 문서·코드와 구분합니다.
규칙 충돌은 정해진 우선순위로 해결하며, 운영 정책 충돌이나 해소되지 않은 요구사항은
기록하고 사용자 판단이 필요한 항목으로 반환합니다.

## infra-terraform 적용안

- 대상: `../infra-terraform`. 실행 시에는 절대 경로와 기준 commit을 확정합니다.
- 필수 근거: `ARCHITECTURE.md`, `README.md`, `docs/SETUP.md` 및 대상 모듈 문서.
- 수집 후보: Markdown과 Terraform 소스. state, plan, 실제 tfvars, 숨김 디렉터리,
  자격 증명, 외부 링크와 provider 바이너리는 제외합니다.
- 초기 작업: `tf-modules/network/security-group`의 요구사항과 입력·출력·사용 예시 설계.
- 공통 모듈은 backend와 계정별 provider 설정을 소유하지 않습니다.
- interfaces는 도메인 조합을 담당하고 공통 모듈에서 상위 계층을 역참조하지 않습니다.
- accounts/projects는 배포 및 state 경계입니다. source 경로와 state 소유권을 확인합니다.
- 계정, 리전, 버전, 트래픽 요구사항과 미정 정책을 임의의 운영값으로 확정하지 않습니다.
- 기존 `policy/NETWORK_POLICY.md`는 검토 초안입니다. 채택 여부와 적용 범위를 확정한 뒤
  프로젝트 규칙에 연결하고 미정 항목을 구현된 정책처럼 취급하지 않습니다.

검증 후보는 변경된 Terraform 디렉터리의 fmt 검사와 초기화된 모듈·배포 루트별 validate입니다.
provider/module 설치와 backend 초기화는 선행 조건으로 따로 다룹니다.
리소스가 없는 자리표시자의 검사 성공만으로 기능 구현 완료를 판단하지 않습니다.
plan/apply/destroy 및 state 조작은 별도 실행 권한과 검토 경로를 둡니다.

## 작업 단위별 구분

| 대상 | 주요 확인 항목 |
| --- | --- |
| tf-modules | 입력·출력, 재사용성, provider 요구사항, 상위 계층 역참조 방지 |
| interfaces | 하위 모듈 조합, source 경로, 입력과 출력 전달 |
| accounts/projects | provider 구성, backend/state 경계, 대상 계정과 기존 리소스 소유권 |

첫 사례는 security-group 모듈로 제안하되 실제 입력·출력과 통신 요구사항은 별도 검토합니다.
단순 fmt·validate 외에 요구사항을 확인할 Terraform 테스트나 보안 검사가 필요한지는
작업별로 결정합니다. 모델 및 에이전트 구현 언어는 아직 선택하지 않았습니다.
