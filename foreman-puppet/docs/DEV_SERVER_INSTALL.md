# 1단계 개발 서버 설치 준비

현재 단계는 설치 입력과 사전 점검 준비다. EC2 생성·원격 접속·패키지 설치·CA 초기화는
아직 하지 않았다. [3단계 구축 계획](PHASED_ROLLOUT.md)의 첫 단계만 다룬다.

관리 대상은 Ubuntu 22/24/26, Rocky 8/9, Amazon Linux 2/2023까지 요구한다.
관리 서버 OS와 구분하며 [OS·엔진 호환성](OS_COMPATIBILITY.md)을 따른다.
엔진은 OpenVox로 선택했으며 AL2만 Agent 8 계열 예외를 둔다.

서버/Agent별 실행 파일과 JSON 입력은 [bootstrap](../bootstrap/README.md)에 구현했다.
설치 버전 기준은 다음과 같다: **Foreman 5.0.1 + Server 9.2.0 + Agent 9.4.0, AL2 Agent 8.33.0**.
실제 설치·통합 검증은 아직 수행하지 않았다.

관리 서버/대상별 설치 목록·버전과 보안 수정 중심 업데이트 정책은
[아키텍처 결정](ARCHITECTURE_GUIDE.md#최초-개발운영-서버-구성과-버전)을 따른다.
설치 실행기는 Bash+jq와 설치된 OpenVox Ruby로 전환했다. Python/PyYAML은 필요 없다.

## 설치 기준표

| 항목 | 준비 기준 | 상태 |
| --- | --- | --- |
| 구성 | 개발 LB + Server1에 Foreman·Compiler·Smart Proxy·로컬 PostgreSQL 16. 운영도 별도 같은 1단계 적용 | 합의 완료 |
| 관리 OS | Ubuntu 24.04 amd64 | 공식 지원 확인, 제안 기준 |
| 서버 자원 | 8 vCPU·32 GiB RAM·100 GiB SSD | 소수 Agent 검증용 후보, 성능 보장 아님 |
| Foreman | 5.0.1 | 공식 설치 경로 확인, 정확한 패키지 revision 미고정 |
| Puppet 계열 엔진 | OpenVox Server 9.2.0 / Agent 9.4.0, AL2 Agent 8.33.0 | 제품·계열 선택, 통합 검증 전 |
| DB | Ubuntu 기본 PostgreSQL 16 계열, 로컬 전용 | 기본 패키지 확인, 실제 의존성·설치 검증 전 |
| 기존 서버 | 사용자가 서버 보유 확인. 새 EC2 생성 제외 | 실제 FQDN·AWS 위치·OS·사양 확인 대기 |
| 인증서 | 사내 웹 PKI + 내장 CA, SAN·최초 서명·CA 지문 공급 검증 | 첫 연결 전 필요 |
| 최초 Agent | Ubuntu 24.04 1대, development/dev, role::base | 실제 노드 미정 |

Foreman 공식 Quickstart는 Ubuntu 24.04와 OpenVox 8 저장소 경로를 제공한다.
OpenVox는 Puppet 호환 프로젝트이며 실제 제품/패키지명은 구분한다. OpenVox 설치 문서는
9 계열도 안내하고 8은 EOL 전 critical/security 수정 대상으로 설명한다. 여기서는 Foreman의
기본 안내와 다른 9 계열을 선택했으므로 운영 전 지원 기간·패키지/모듈 호환성을 검증한다.
현재 Ruby 테스트의 Puppet 8.10.0 고정은 실제 설치 제품·패치 버전 승인을 의미하지 않는다.

[Foreman 5.0 Quickstart](https://docs.theforeman.org/5.0/Quickstart/index-foreman-deb.html),
[OpenVox 설치·지원 계열](https://voxpupuli.org/openvox/install/),
[Ubuntu Noble PostgreSQL 메타패키지](https://packages.ubuntu.com/noble/postgresql)를
2026-11-17 확인했다. Quickstart의 별도 상세 Installing 문서는 당시 미완성으로 표시되므로
필요 옵션은 [Foreman 5.0 Manual](https://theforeman.org/manuals/5.0/index.html)과 설치할
foreman-installer의 --full-help를 대조해야 한다. 모든 설정 조합을 검증한 상태는 아니다.

## 입력 파일과 사전 점검

[dev.example.yaml](../server/dev.example.yaml)은 설치 입력을 정리하는 표본이다.
Hiera나 foreman-installer가 자동으로 읽는 파일이 아니다. null은 미정이며 예시 IP/도메인으로
대체해 실제 설치하지 않는다. 비밀번호·관리 토큰·개인키는 기록하지 않는다.

[server-preflight.sh](../scripts/server-preflight.sh)는 대상 개발 VM에서 실행하는 읽기 전용 점검이다.
실제 네 이름을 인자로 전달한다. 아래 이름은 형식 설명용이며 스크립트는 예시 도메인을 거부한다.

```sh
bash scripts/server-preflight.sh --help
# 준비된 실제 VM에서, 아래 인자를 실제 이름으로 바꾼 후 실행한다.
bash scripts/server-preflight.sh \
  mgmt-dev-01.example.internal \
  foreman-dev.example.internal \
  puppet-dev.example.internal \
  puppet-ca-dev.example.internal
```

확인 대상은 OS/아키텍처, CPU·메모리·/var 여유 공간, hostname -f, 네 이름의 로컬 IPv4
주소 해석, 443/8140/8443/5432 기존 리스너다. 이미 서비스가 있는 서버는 새 설치를 멈추고
상태를 확인한다. AWS API·SG·상대 노드 연결·IPv6·TLS·PKI·패키지 가용성은 점검하지 않는다.
이 스크립트의 자원 임계치는 프로젝트의 소수 노드 검증 기준이며 벤더 공식 최소 사양이 아니다.

시간 동기화, forward/PTR DNS, Agent 경로에서의 DNS/접속, 저장소 접근, 사내 신뢰 체인,
백업 목적지는 별도로 확인한다. VM hostname/certname과 서비스 접속 별칭을 구분하고
인증서에 필요한 SAN을 넣는다. 1단계의 네 이름은 같은 VM을 가리킬 수 있다.

## 다음 설치 절차에서 구현할 내용

1. 기존 서버의 실제 입력·제품을 확정하고 사전 점검을 수행한다. 기존 업무·설치 이력이
   있으면 덮어쓰지 않고 전용 관리 서버로 사용할 수 있는지 먼저 확인한다.
2. 승인한 저장소 키/공급 경로를 구성하고 apt-cache policy로 Foreman·installer·Proxy·
   엔진·PostgreSQL의 정확한 후보 버전/의존성을 기록한다. 기존 Puppet/OpenVox 패키지를
   임의로 교체하지 않는다. 운영은 같은 검증 버전을 재현한다.
3. 설치할 installer의 옵션에서 로컬 DB·Foreman Puppet 플러그인·Puppet Server 및
   ENC/Facts/Report 연동·Smart Proxy 기능을 명시적으로 확인한다.
   foreman-installer 기본 실행만으로 원하는 Puppet 통합이 모두 구성됐다고 판단하지 않는다.
4. 사내 PKI 발급/신뢰 및 기존 CA 존재 여부를 확인하고 설치한다. 잘못된 이름의 CA를
   먼저 생성한 뒤 인증서를 삭제해 재설치하는 절차를 기본 경로로 사용하지 않는다.
5. Foreman 접속·Smart Proxy 기능·DB 연결·개발 코드 환경을 확인한 뒤 Host Group과 Role을 구성한다.
6. 첫 Agent 연결·0/2 종료 코드·동일 실행 Report·두 번째 적용 무변경을 확인한다.
   role::unmanaged는 최초부터 배정하지 않고 [최초 설정 흐름](ROLE_LIFECYCLE.md)을 따른다.

위 절차 중 저장소·패키지·설정 실행기는 bootstrap에 분리 구현했다. 실제 입력값·PKI 발급·분류 자동화와 OS 설치 검증은 남아 있다. 실제 입력이 준비되면 계획을 검토하고 bootstrap의 개별 단계를 대상 서버에서 검증한다.
Foreman 웹/API·Proxy는 사내 인증서, Agent 통신은 OpenVox 내장 CA를 사용한다. bootstrap은 별도 ca-init에서 최초 CA를 명시적으로 초기화하며 configure는 기존 CA를 검증한다. Agent 서명·갱신·정기 실행은 별도 검증 후 진행한다.
