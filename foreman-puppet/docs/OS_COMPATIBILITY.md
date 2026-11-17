# 관리 대상 OS와 엔진 선택

## 관리 서버와 Agent의 OS는 별개

Foreman 관리 서버는 Ubuntu 24.04 amd64를 설치 기준 후보로 둔다.
관리 대상 Agent는 아래 OS를 요구 범위로 한다. 모든 대상 OS에 Foreman을 설치하지 않는다.
OpenVox는 필수 제품이 아니라 Puppet 호환 엔진 후보이며 아직 제품을 확정하지 않았다.
기존 특정 Puppet 제품/라이선스 요구는 없다는 응답을 반영한다.

| 관리 대상 OS | 프로젝트 아키텍처 | OpenVox 8 공식 플랫폼 표 | 현재 코드 / 실제 적용 |
| --- | --- | --- | --- |
| Ubuntu 22.04 | amd64, arm64 | Agent 패키지 대상 | Catalog fixture 검증 / 실기 미검증 |
| Ubuntu 24.04 | amd64, arm64 | Agent 패키지 대상 | Catalog fixture 검증 / 실기 미검증 |
| Ubuntu 26.04 | amd64, arm64 | Agent 패키지 대상 | Catalog fixture 검증 / 실기 미검증 |
| Rocky 8 | x86_64, aarch64 | Enterprise Linux 8의 rebuild 대상 | Catalog fixture 검증 / 실기 미검증 |
| Rocky 9 | x86_64, aarch64 | Enterprise Linux 9의 rebuild 대상 | Catalog fixture 검증 / 실기 미검증 |
| Amazon Linux 2 | x86_64, aarch64 | Agent 패키지 대상 | Catalog fixture 검증 / 실기 미검증 |
| Amazon Linux 2023 | x86_64, aarch64 | Agent 패키지 대상 | Catalog fixture 검증 / 실기 미검증 |

기존 Ubuntu 20.04 코드/fixture는 호환 유지를 위해 남긴다. 이번 최신 필수 목록에는 없으며,
과거 저장소 파일이 존재하는 것과 현재 공식 지원/보안 수명은 별도다.
모든 행의 실제 패키지 patch·서명·의존성·실행 및 Foreman 연동은 선택한 버전으로 검증해야 한다.

## 선택 기준

- Foreman 5.0 공식 Quickstart의 명시된 경로는 OpenVox 8이다. 이 경로와 AL2 요구 때문에
  초기 검증 후보를 8 계열로 둔다. 기존 Puppet DSL·Role/Profile·Hiera 구조를 사용한다.
- OpenVox 9 공식 플랫폼 표에는 Amazon Linux 2 빌드가 없다. 전체 노드를 무조건 최신
  9 계열로 통일하는 안은 현재 요구에 맞지 않는다.
- OpenVox 8은 현재 최신 주계열이 아니며 EOL 전 critical/security 수정 대상으로 안내된다.
  운영 확대 전 엔진·OS 수명과 업그레이드 방침을 확인한다.
- 다른 Puppet 제품을 선택할 수도 있으나 해당 공급자의 패키지 권한·OS 지원·Foreman
  통합을 별도로 검증한다. Puppet Enterprise를 커뮤니티 installer의 대체 패키지처럼 취급하지 않는다.
- 8/9 혼합 Agent/Server 버전은 이번에 검증하지 않았으므로 자동 대안으로 적용하지 않는다.

자료 확인일: 2026-11-17.
[Foreman 5.0 Quickstart](https://docs.theforeman.org/5.0/Quickstart/index-foreman-deb.html),
[OpenVox 8 지원 플랫폼](https://docs.openvoxproject.org/openvox/8.x/supported_platforms.html),
[OpenVox 9 지원 플랫폼](https://docs.openvoxproject.org/openvox/9.x/supported_platforms.html),
[OpenVox 설치 및 계열 정책](https://voxpupuli.org/openvox/install/).

## 코드 변경 범위와 검증의 의미

profile::base는 Ubuntu 22.04와 Amazon Linux 2/2023을 추가로 허용한다.
Amazon fixture의 os.name은 Amazon, os.release.full은 2 또는 2023.x이며
실제 Agent에서 수집한 Facts와 대조한다. 다른 버전이나 지원하지 않는 아키텍처는 거부한다.
SSH 서비스 매핑은 Ubuntu=ssh.service, Rocky/Amazon=sshd.service다.

Catalog 테스트는 기존 Ubuntu 20.04를 포함한 8개 OS 버전 × OS별 2개 아키텍처 ×
2개 환경 × 2개 기존 Role 조합 × 3개 CSP × 5개 GPU 상태의 960개 기본 조합을 사용한다.
새 팀 Role·미관리·SSH 활성화/제외는 별도 사례로 검증한다.
이 테스트는 Agent 바이너리를 각 OS에서 실행하거나 패키지 provider를 실제 적용하는 테스트가 아니다.

## 실제 OS 검증 시 남은 항목

1. 정확한 패키지 버전·서명·저장소, Facter의 OS/Arch 값과 CA 신뢰를 확인한다.
2. 각 OS에서 Agent 설치·등록·공통 패키지·예시 파일·Report·두 번째 실행 무변경을 확인한다.
3. SSH는 이미지의 OpenSSH 버전·Include·drop-in 경로·서비스명·SELinux/실행 디렉터리를 확인한다.
   특히 AL2 등 오래된 OpenSSH에서 서버 Include를 지원한다고 가정하지 않는다.
   현재 SSH Profile은 Include가 없으면 적용을 거부한다. 이런 이미지는 전체 파일 관리 등
   별도의 안전한 구현/검증이 필요하며 현재 SSH Profile의 실기 호환이 완료된 것이 아니다.
4. Banner·일반/root 패스워드 새 로그인, 기존 세션 유지, 검증/반영 실패 처리를 확인한다.
5. 전역 제외와 미관리 최초 적용→성공 확인→제외 전환을 각 OS에서 확인한다.

실기 통과 전에는 SSH manage=false를 유지한다. DNS/NTP·저장소·cloud-init 등의 후속
Profile도 OS별 백엔드 차이를 검증한 후 활성화하며, 패키지 대상이라는 이유로 모든 설정의
동작을 보장하지 않는다.
