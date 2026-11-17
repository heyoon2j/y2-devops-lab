# Foreman / OpenVox 설치 파일

서버와 Agent의 저장소·패키지·설정을 분리한다. 설치 자동화의 진입점이며
실제 서버에서 실행하지 않는다. 상세 입력·실행·검증 범위는 이 문서에 함께 정리한다.

```text
bootstrap/
├── server/
│   ├── foreman-repo.sh       # Foreman 저장소
│   ├── openvox-repo.sh       # OpenVox Server용 저장소
│   ├── foreman-install.sh    # Foreman 패키지
│   ├── openvox-install.sh    # OpenVox Server 패키지
│   ├── foreman-config.sh     # Foreman·로컬 DB·Proxy 구성
│   └── openvox-config.sh     # Compiler·Foreman 연동 구성
├── agent/
│   ├── repo.sh               # OS/Agent 계열별 저장소
│   ├── install.sh            # Agent 패키지
│   └── config.sh             # 접속·인증·환경·외부 Facts
├── examples/                 # 비밀값 없는 실행 입력 예시
└── lib/                      # 검증·명령 계획·공통 처리
```

## 현재 기준과 범위

- 관리 서버: Ubuntu 24.04 x86_64, Foreman 5.0.1, OpenVox Server 9.2.0 + 같은 VM의 Agent 9.4.0.
- 관리 대상: Ubuntu 22.04/24.04/26.04, Rocky 8/9, AL2023은 Agent 9.4.0. AL2만 Agent 8.33.0.
- Agent의 x86_64/aarch64 입력을 지원한다. Foreman 관리 VM은 x86_64만 허용한다.
- PostgreSQL 16 로컬 배치다. RDS 이전은 별도 2단계이며 이 스크립트에 포함하지 않는다.
- 실행기는 Bash + Python 3.7 이상 표준 라이브러리를 사용한다. AL2에도 Python 3가 필요하다.
- 실행 파일은 얇은 진입점이고 공통 검증·명령 계획은 lib/bootstrap.py에 모았다.
  Puppet 코드 배포 도구와 설정 지속 관리 Profile을 대신하는 파일이 아니다.

**파일 작성·격리 검증만 완료했으며 실제 OS의 설치·Foreman/OpenVox 9 통합은 미검증이다.**
Foreman 공식 Quickstart가 OpenVox 8을 안내하므로 9용 패키지·installer 옵션은 실제 대상에서
확인해야 한다. config 실행기는 설치된 installer의 --full-help에 없는 옵션을 거부한다.
이 검사는 옵션 존재만 확인하며 모든 옵션 조합의 런타임 호환성을 보장하지 않는다.

## 입력 준비

examples/server.json, agent.json, agent-amzn2.json을 bootstrap/local/ 또는 저장소 밖으로
복사해 사용한다. local/은 Git 제외다. 입력의 null은 미정이며 config/install 적용을 차단한다.
다른 프로젝트 파일을 수정하지 않는다. server/dev.example.yaml은 기존 계획표이며 실행 입력은 이 JSON이다.

| 입력 | 설명 |
| --- | --- |
| os.id/version/architecture | 대상 실제 OS와 uname 아키텍처. --apply 시 로컬 OS와 대조 |
| host_fqdn | 관리 VM hostname -f와 일치할 실제 FQDN |
| foreman_fqdn / puppet_fqdn / ca_fqdn | 논리 접속 이름. DNS와 인증서 SAN을 별도로 준비 |
| puppet_certname | 관리 서버의 Puppet 인증서 이름. 서비스 별칭과 구분 |
| certname | Agent 고유 인증서 이름 |
| repository_keys | 공식 키의 **primary fingerprint**. 신뢰할 별도 경로에서 확인 |
| package_versions | apt/rpm의 **전체 Version-Release 문자열**. upstream 번호만 보고 배포판 revision을 추정하지 않음 |
| tls.ca_cert / host_cert / host_key | 사내 PKI가 발급해 대상 VM에 배치한 파일의 절대 경로 |
| installer.*_args | Foreman/OpenVox 구성에 전달할 공개 옵션. 예시는 대상 installer와 대조 |

Foreman 설치에는 foreman, foreman-installer, foreman-proxy, ruby-foreman-puppet,
postgresql-16의 전체 버전이 필요하다. OpenVox Server 설치에는 openvox-agent와
openvox-server 버전이 필요하다. Proxy·installer·플러그인 버전은 Foreman 본체와 숫자가
항상 같다고 가정하지 않으며 5.0 저장소의 호환 패키지를 선택한다.

예를 들어 저장소 준비 후 다음 **조회 명령**으로 확인한다.

```sh
apt-cache policy foreman foreman-installer foreman-proxy ruby-foreman-puppet postgresql-16 openvox-agent openvox-server
# RPM 대상에서는 해당 OS에서 실행
# yum --showduplicates list openvox-agent      # AL2
# dnf --showduplicates list openvox-agent      # Rocky/AL2023
```

top-level 패키지 버전은 고정·설치 후 대조하지만 간접 의존성 전체의 저장소 snapshot을
생성하는 도구는 아니다. 서명된 사내 미러로 재현성을 강화할 수 있다.
다른 이름의 기존 Foreman/Puppet/OpenVox 저장소가 중복되어 있지 않은지도 사전에 확인한다.
스크립트는 기존 저장소 파일을 일괄 삭제하지 않는다.

## 실행 순서

기본은 **변경 없는 JSON 계획 출력**이다. 계획의 unresolved 항목을 먼저 해결한다.
repository 단계에서 입력이 모두 준비된 경우 unresolved가 비어 있을 수 있다.
--apply는 root로 실제 대상에서 명시할 때만 파일·저장소·패키지·서비스 구성을 변경한다.

```sh
# 저장소 루트의 foreman-puppet에서 실행
bash bootstrap/server/foreman-repo.sh --config bootstrap/local/server.json
bash bootstrap/server/openvox-repo.sh --config bootstrap/local/server.json
bash bootstrap/server/openvox-install.sh --config bootstrap/local/server.json
bash bootstrap/server/foreman-install.sh --config bootstrap/local/server.json
bash bootstrap/server/foreman-config.sh --config bootstrap/local/server.json
bash bootstrap/server/openvox-config.sh --config bootstrap/local/server.json

# 실제 적용 예시: 계획 확인 및 필수 입력 준비 후, 대상 VM에서 실행
# sudo bash bootstrap/server/foreman-repo.sh --config /root/bootstrap/server.json --apply
```

OpenVox 저장소와 패키지를 먼저 준비해 Foreman installer가 사용할 엔진을 공급한다.
Foreman config는 Puppet/Proxy 모듈 실행을 건너뛰고 웹·DB를 구성한다.
OpenVox config는 **같은 Foreman 인자 + OpenVox 인자를 함께 사용**해 두 구성을 유지한다.
일부 기존 installer 답변을 삭제하거나 DB/CA를 초기화하는 동작은 하지 않는다.
config 단계는 installer를 통해 서비스를 시작/변경할 수 있으므로 점검 시간에 실행한다.

```sh
bash bootstrap/agent/repo.sh --config bootstrap/local/agent.json
bash bootstrap/agent/install.sh --config bootstrap/local/agent.json
bash bootstrap/agent/config.sh --config bootstrap/local/agent.json
# AL2는 agent-amzn2.json 형식의 os.id=amzn, os.version=2 사용
```

Agent config는 puppet.conf의 기존 다른 키/섹션을 보존하고 관리 키만 [main]에 설정한다.
같은 키가 다른 섹션에 있으면 우선순위 혼동을 막기 위해 거부한다. 재작성 시 주석/서식은 보존하지 않는다.
facts.d/foreman_puppet.json에는 deploy_env와 선택적 team만 기록한다. Role/Host Group은 Fact로 넣지 않는다.
중복 deploy_env/team 외부 Facts 파일은 등록 과정에서 정리/대조해야 하며 자동 삭제하지 않는다.
Agent config는 서비스 시작·enable·CSR 생성·첫 Catalog 적용을 수행하지 않는다.
인증·Foreman 분류를 확인한 뒤 puppet agent --test --detailed-exitcodes를 수동 검증하고,
0/2와 해당 Report를 확인한 후 정기 실행을 켠다. [최초 적용 흐름](../docs/ROLE_LIFECYCLE.md) 참조.

## 사내 인증서와 비밀값

이 구현은 **외부 PKI가 미리 발급한 인증서를 사용하는 경로**다. CA 서명키를 만들거나,
Puppet Intermediate CA를 초기화/위임하거나, 인증서 발급·갱신 API를 자동화하지 않는다.
CA 발급 방식을 나중에 결정하기로 했으므로 PKI 파일이 없으면 config --apply를 중단한다.
HTTP 무인증·인증서 검증 해제·autosign 우회 옵션을 제공하지 않는다.

서버에는 tls.host_cert/key(웹·ENC/Report 클라이언트·Proxy용) 외에 Puppet Server의 표준 위치에
별도 인증 자료도 준비한다. 같은 VM의 신원을 공유할지 별도 발급할지는 사내 PKI 절차에 따른다.

```text
/etc/puppetlabs/puppet/ssl/
├── certs/ca.pem
├── certs/<puppet_certname>.pem       # puppet_fqdn SAN 포함
├── private_keys/<puppet_certname>.pem
└── crl.pem                          # 사내 PKI CRL
```

인증서/키 일치·CA 검증·접속 이름을 확인한다. 별칭·웹/클라이언트 EKU·중간 CA 체인·CRL·
갱신·서비스 계정의 키 읽기 권한은 실제 PKI/OS에서 추가 검증한다. 기존 Puppet CA가 발견되면
자동으로 외부 PKI로 바꾸지 않는다. 이미 있는 CA 키·인증서·DB를 지우는 복구 절차를 넣지 않는다.

비밀번호·OAuth key/secret·관리 토큰·개인키 내용은 JSON·Git·CLI 인자에 넣지 않는다.
installer가 생성/보관하는 비밀값은 기존 root-only answers를 유지하고 안전하게 백업한다.
installer는 초기 관리자 비밀번호를 출력할 수 있어 config 로그는
/var/log/foreman-openvox-bootstrap에 root-only로 보관한다. 실패 시에도 이 파일에서 확인한다.

Smart Proxy 자동 등록은 토큰 입력이 없으므로 끈다. 설치 후 Proxy를 HTTPS URL·고유 이름으로
등록하고 Puppet 기능을 확인한다. Foreman의 인증서 신뢰·trusted hosts/client 허용과
Compiler의 environment_classes API 허용, Host Group·Boolean puppet_managed·Role 배정은
이후 관리 API/설정 단계에서 검증해야 한다. 웹/DB 설치 성공만으로 Agent 등록 완료라 판단하지 않는다.

## 재실행·제약과 테스트

- --apply는 root·실제 OS·필수 입력을 확인하고 로컬 잠금으로 동시 실행을 막는다.
- 기존 proprietary/legacy puppet-agent/puppetserver가 발견되면 암묵적으로 교체하지 않는다.
- apt 설치는 --no-remove와 임시 policy-rc.d로 새 서비스의 postinst 시작을 억제한다.
  기존 policy-rc.d는 덮어쓰지 않으므로 그 정책의 시작 차단 여부는 별도 확인한다.
- RPM 패키지의 scriptlet 동작은 공급 패키지에 따르며 시작을 강제로 억제하지 않는다.
  반드시 최초 Agent 등록 전 서비스 상태를 확인한다. 운영 중 노드의 무중단 업그레이드 도구는 아니다.
- 원자적 파일 교체는 개별 파일 단위다. 전체 설치 트랜잭션/자동 rollback을 보장하지 않는다.
- 버전 검증 실패·키 교체·설정 중단 후에는 원인을 확인하고 해당 단계만 다시 실행한다.
- prerequisite: Bash, Python 3.7+, GnuPG, OpenSSL, apt 또는 rpm/yum/dnf 및 저장소 HTTPS 접근.
  이 도구들을 설치하는 것과 사전 DNS·사양 점검은 [사전 점검](../scripts/server-preflight.sh)과 별개 준비다.

```sh
python3 tests/bootstrap_test.py
```

격리 테스트는 9개 진입점의 help/기본 계획, 7개 OS 버전·2개 아키텍처의 저장소 선택,
AL2의 8 계열 예외, 정확한 버전·미정 입력·OS·인증서 이름·CA 보호 옵션·환경/Fact 경계를 확인한다.
실제 저장소 키 다운로드·설치·서비스·TLS·Foreman/OpenVox 연동은 실행하지 않는다.

참고: [Foreman installer 옵션](https://theforeman.org/manuals/5.0/index.html),
[OpenVox 저장소 설정](https://voxpupuli.org/openvox/install/),
[Agent/Server 8→9 전환](https://docs.openvoxproject.org/openvox/9.x/upgrade_major.html).
