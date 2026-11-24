# Foreman / OpenVox 설치 파일

설정 원본과 실행 단계를 분리한다. 기본 실행은 변경 없는 JSON 계획 출력이며 --apply를 명시해야
실제 대상에서 적용한다. 이 저장소에서 실제 EC2·NLB·DB·CA를 생성하거나 서비스를 실행하지 않았다.

## 구성과 런타임

```text
bootstrap/
├── config/
│   ├── repos/apt/                       # Ubuntu deb822 .sources 원본
│   ├── repos/yum/                       # Rocky/Amazon Linux .repo 원본
│   ├── server/foreman.answers.yaml.tmpl  # 내부 HTTPS·로컬 PostgreSQL
│   ├── server/openvox.answers.yaml.tmpl  # 내장 CA·Compiler·Proxy·연동
│   ├── agent/puppet.conf.tmpl            # Agent 접속·실행 설정, 인증서는 기본 SSL 경로
│   ├── packages/                        # 설치할 패키지 목록
│   └── versions.json                    # upstream 기준 버전
├── server/
│   ├── foreman-repo.sh / openvox-repo.sh
│   ├── openvox-install.sh / foreman-install.sh
│   ├── ca-init.sh                       # 명시적인 최초 CA 초기화/기존 완전한 CA 검증
│   └── configure.sh                     # 두 answers를 함께 적용
│       # foreman-config.sh와 openvox-config.sh도 같은 전체 구성의 호환 진입점
├── agent/repo.sh / install.sh / config.sh
├── user-data/                           # cloud-init·직접 API 호출 Bash 함수·독립 Go 구현
├── examples/                            # 비밀값 없는 입력
└── lib/
    ├── bootstrap.sh                     # Bash+jq: 저장소·패키지 단계 및 진입점
    └── configure.rb                     # OpenVox의 Ruby 표준 라이브러리: 설정·CA 처리
```

**Python/PyYAML은 사용하지 않는다.** 초기 repo/install에는 Bash·jq·curl·GnuPG·OpenSSL·coreutils(timeout)·
flock·OS 패키지 관리자가 필요하다. 이 도구는 이미지/초기 준비에서 설치한다.
config/ca-init는 먼저 설치한 openvox-agent의 /opt/puppetlabs/puppet/bin/ruby를 사용한다.
시스템 Ruby가 있으면 대체 실행도 가능하지만 대상 노드에 별도 Ruby 버전 관리 체계를 만들지 않는다.
FOREMAN_BOOTSTRAP_RUBY는 격리 테스트/관리 작업에서 실행 경로를 명시하는 옵션이다.
서버 answers는 YAML(Psych), JSON, INI 처리에 Ruby 표준 라이브러리만 사용한다.

관리 서버는 Ubuntu 24.04 x86_64, Foreman 5.0.1/OpenVox Server 9.2.0/Agent 9.4.0/로컬 PostgreSQL 16 기준이다.
Agent는 Ubuntu 22/24/26, Rocky 8/9, AL2023의 x86_64/aarch64에 9.4.0, AL2만 8.33.0을 사용한다.
지원 입력과 실제 OS 설치·Foreman/OpenVox 9 통합 검증은 다르며 후자는 아직 미검증이다.
단계별 인프라는 [개발·운영 계획](../docs/PHASED_ROLLOUT.md)을 따른다.

## 입력 준비

examples의 JSON을 Git 제외인 bootstrap/local/ 또는 저장소 밖으로 복사한다.
null은 미정 값이며 필요한 단계의 --apply를 차단한다. 비밀키·PAT·비밀번호는 입력에 넣지 않는다.

### 입력 파일은 언제 만드는가?

**설치 명령 실행 전에 관리자가 예시를 복사해 직접 만든다.** --config는 파일 생성 옵션이 아니라
이미 만든 JSON을 읽는 옵션이다. .tmpl 파일도 입력 화면이 아니며 JSON 값을 치환할 설정 원본이다.

```text
examples/server.json — 기본 구조·미정 null이 있는 예시
        ↓ 최초에 복사
local/server.json — 관리자가 실제 값을 입력하는 파일(Git 제외)
        ↓ --config로 전달
실행기가 .tmpl의 변수를 치환해 계획 출력
        ↓ 같은 명령에 --apply 지정
대상 서버의 설정·패키지에 적용
```

관리 서버에 프로젝트 파일을 준비한 다음 실행한다. 아래 /path/to는 실제 저장소 경로로 바꾼다.
최초 복사 예시이며 입력 파일이 이미 있으면 덮어쓰지 말고 기존 파일을 편집한다.

```sh
cd /path/to/y2-devops-lab/foreman-puppet
mkdir -p bootstrap/local
cp bootstrap/examples/server.json bootstrap/local/server.json
vi bootstrap/local/server.json
```

처음에는 OS·host_fqdn·Foreman 웹/내부 서비스/Puppet/CA 접속 이름·ca_mode·서버 내부용 인증서 경로·저장소 키 지문을
확인해 입력한다. 호스트 이름은 예시가 아닌 실제 값이어야 하고 인증서 파일은 대상 서버에 준비한다.
repo 단계는 해당 OS와 키 지문이 준비되면 실행할 수 있다. package_versions의 전체 revision을
아직 모르면 저장소 적용 후 조회해서 **같은 server.json을 다시 편집**한다. install/ca-init/configure
전에 해당 단계의 필수 값이 모두 준비되어야 한다. null이 있는 모든 단계가 한꺼번에 실행 가능한 것은 아니다.

각 단계는 기본 계획 출력의 unresolved를 먼저 확인한다. unresolved가 비어 있어도 실제 DNS·TLS·
NLB/SG·계정 권한 검증을 대체하지 않는다. 실제 적용은 대상 서버에서 sudo와 --apply로 실행한다.

```sh
# 저장소 등록 계획 → 입력 확인 후 실제 등록(예시)
bash bootstrap/server/foreman-repo.sh --config bootstrap/local/server.json
sudo bash bootstrap/server/foreman-repo.sh --config bootstrap/local/server.json --apply
bash bootstrap/server/openvox-repo.sh --config bootstrap/local/server.json
sudo bash bootstrap/server/openvox-repo.sh --config bootstrap/local/server.json --apply

# 새 저장소에서 실제 배포판 버전 조회 → 같은 입력 파일의 package_versions 수정
apt-cache policy foreman foreman-installer foreman-proxy ruby-foreman-puppet postgresql-16 openvox-agent openvox-server
vi bootstrap/local/server.json
```

그다음 아래 Server1 단계에서 OpenVox 설치 → Foreman 설치 → CA 초기화 → 설정 적용 순으로
계획/적용을 진행한다. config/ca-init 계획도 OpenVox Agent의 Ruby 설치 후 실행한다.
처음 입력한 파일을 단계마다 새로 복사하는 것이 아니라 **계속 같은 파일을 사용**한다.
개발·운영은 다른 서버에서 각자 입력 파일을 만들며 FQDN·인증서·CA 신원을 공유하지 않는다.

| 입력 | 의미 |
| --- | --- |
| os.id/version/architecture | 실제 대상 OS/버전/아키텍처, --apply에서 대조 |
| host_fqdn | 관리 VM hostname -f와 같은 고유 이름 |
| foreman_fqdn / foreman_service_fqdn / puppet_fqdn / ca_fqdn | 웹 443·내부 연동 8444·Agent 8140 NLB 이름과 단일 CA 이름 |
| puppet_certname | 최초 관리 서버에서 host_fqdn과 같아야 함 |
| ca_mode | 최초 관리 서버는 internal_primary만 지원. Server2/Standby는 후속 단계 |
| tls.ca_cert/host_cert/host_key | 서버 내부 HTTPS/서비스 인증용 CA·인증서·키 경로. NLB ACM 인증서와 별도 |
| certname | Agent 고유 이름, 이미지에서 인증서/개인키를 공유하지 않음 |
| puppet_environment | Agent 최초 코드 환경 development/production |
| puppet_ca_fingerprint | Agent 입력에만 사용. 신뢰할 별도 경로에서 확인한 CA SHA-256 지문(콜론 구분) |
| repository_keys | 저장소 서명키 primary fingerprint. Foreman 키의 실측값은 별도 확인 |
| package_versions | 저장소에서 조회한 전체 Version-Release 문자열. 배포판 revision을 추정하지 않음 |

NLB ACM 인증서의 SAN에는 foreman_fqdn을, 서버 내부용 인증서 SAN에는 host_fqdn과 foreman_service_fqdn(8444 접속 이름)을 포함한다. 필요한 웹/클라이언트 EKU·
서비스별 허용 목록·읽기 권한은 실제 PKI/설치 환경에서 추가 검증한다.
내장 CA 서버 인증서는 host_fqdn, puppet_fqdn, ca_fqdn을 포함하도록 초기화한다.
서버별 인증서와 CA 키를 구분하고 개발 CA를 운영에 복제하지 않는다.

배포판 전체 버전 확인 예시:

```sh
apt-cache policy foreman foreman-installer foreman-proxy ruby-foreman-puppet postgresql-16 openvox-agent openvox-server
# RPM 대상에서는 yum/dnf --showduplicates list openvox-agent
```

간접 의존성 전체의 snapshot을 제공하지 않는다. 실제 revision은 기록하고 보안 수정이 필요한 경우
개발 검증 후 갱신한다. 기존 Puppet 패키지를 암묵적으로 OpenVox로 교체하지 않는다.

## 개발/운영 Server1의 단계

아래는 **모두 계획 출력**이다. 입력과 공급 경로를 검증한 뒤 대상에서 필요한 명령에만 --apply를 붙인다.
같은 서버에서 각 적용 단계는 로컬 잠금으로 직렬 실행한다.

```sh
bash bootstrap/server/foreman-repo.sh --config bootstrap/local/server.json
bash bootstrap/server/openvox-repo.sh --config bootstrap/local/server.json
bash bootstrap/server/openvox-install.sh --config bootstrap/local/server.json
bash bootstrap/server/foreman-install.sh --config bootstrap/local/server.json
bash bootstrap/server/ca-init.sh --config bootstrap/local/server.json
bash bootstrap/server/configure.sh --config bootstrap/local/server.json
```

계획을 확인한 뒤 실제 적용 명령은 다음과 같다. 앞 절의 저장소 등록과 전체 버전 입력을 완료한 상태에서
각 단계의 계획/결과를 확인하며 한 줄씩 실행한다. 아래 명령을 로컬 작업 PC에서 실행하지 않는다.

```sh
sudo bash bootstrap/server/openvox-install.sh --config bootstrap/local/server.json --apply
sudo bash bootstrap/server/foreman-install.sh --config bootstrap/local/server.json --apply
sudo bash bootstrap/server/ca-init.sh --config bootstrap/local/server.json --apply
sudo bash bootstrap/server/configure.sh --config bootstrap/local/server.json --apply
```

OpenVox 패키지를 먼저 설치해 설정 처리와 Installer가 사용할 Ruby를 확보한다.
ca-init는 패키지 pin·실제 호스트·입력·서비스 중지 상태를 확인한 후 명시적인 초기화를 수행한다.
완전한 기존 CA는 검증만 하고 보존한다. 일부만 남은 CA·기존 외부 PKI SSL 상태·이전 CA 경로는
자동 초기화/변환하지 않고 중단한다. 일반 configure에는 CA setup 명령이 없다.
생성된 CA의 전체 상태를 즉시 암호화된 외부 저장소에 백업하고 지문을 별도 기록한다.

configure는 두 native answers 원본을 병합한다. 기존 비밀값·미관리 모듈 값은 보존하고 root 전용으로 백업한다.
기존 answers는 root 소유 0600이어야 하며 YAML 주석/서식은 재작성된다. 중복 키·템플릿 충돌은 거부한다.
설치된 Installer --full-help와 scenario의 answers 경로를 대조한다. 옵션 존재가 런타임 호환성 보장은 아니다.
기존 server_ca=false 설정은 자동으로 내장 CA로 전환하지 않는다.
Installer는 서비스 시작/변경을 할 수 있고, 출력은 /var/log/foreman-openvox-bootstrap의 root 전용 로그에 저장한다.
DB는 아직 localhost/db_manage=true이며 RDS 이전·Server2 설치는 별도 단계로 구현해야 한다.

내장 CA 발급은 autosign=false로 시작한다. Smart Proxy의 CA 기능을 켜되 자동 등록은 토큰 없이 수행하지 않는다.
설치 뒤 Proxy 등록·Puppet/CA 기능·Foreman 허용 목록·환경/Class API·ENC·Facts/Report를 실제 검증한다.
웹/API는 NLB TLS 443의 ACM → TLS backend 443, 내부 연동은 TCP 8444 → backend 443을 사용한다. ENC/Facts/Report·Proxy 서비스 인증은
foreman_service_fqdn:8444의 NLB TCP passthrough로 연결하고 tls.* 자료를 사용한다. Proxy→Puppet API와 Agent는 내장 CA 신원을 사용한다.
ACM ARN은 [계획 입력](../server/dev.example.yaml)의 NLB 항목에 두며 이 설치 실행기가 AWS에 적용하지 않는다.
서버 내부용 인증서도 별도로 준비해야 한다. [ACM/내부 TLS](../docs/ACM_AND_BACKEND_TLS.md)를 따른다.
CA 자동 갱신은 이번 단계에서 활성화하지 않는다. 기본 유효기간·만료 감시와 수동 갱신/폐기를 준비하고
자동 갱신은 선택 버전에서 CA/Agent 동작·백업·CRL 반영까지 검증한 후 활성화한다.

## Agent 설치·인증서 등록

입력 파일은 **Agent를 설치할 대상 서버에서**, 최초 repo 명령 전에 만든다.
AL2는 agent.json 대신 agent-amzn2.json 예시를 복사한다.

```sh
cd /path/to/y2-devops-lab/foreman-puppet
mkdir -p bootstrap/local
cp bootstrap/examples/agent.json bootstrap/local/agent.json
vi bootstrap/local/agent.json
```

OS·puppet_fqdn·ca_fqdn·고유 certname·코드 환경·저장소 키 지문을 입력한다. 저장소 적용 후 실제
Agent 패키지 전체 버전을 조회해 같은 파일에 기록하고, config 단계 전 신뢰할 경로에서 확인한
내장 CA 지문도 입력한다. 각 단계의 계획을 확인한 뒤 실제 대상에서만 sudo와 --apply를 사용한다.


```sh
bash bootstrap/agent/repo.sh --config bootstrap/local/agent.json
bash bootstrap/agent/install.sh --config bootstrap/local/agent.json
bash bootstrap/agent/config.sh --config bootstrap/local/agent.json
```

Agent config는 puppet.conf만 배치한다. CSR 생성·승인·첫 apply·정기 서비스 시작은 자동 실행하지 않는다.
INI의 미관리 키/섹션은 보존하고 관리 키가 다른 섹션에 중복되면 거부한다. 주석/서식은 재작성된다.
이전 외부 PKI 경로(localcacert/hostcert/hostprivkey/ssldir) override가 있으면 전환 검토 전 중단한다.
기존 Agent CA 지문이나 기존 certname이 입력과 다르면 신원/신뢰를 자동 교체하지 않고 중단한다.

계획에 출력된 bootstrap_instructions.argv는 **다음에 수동 실행할 안내**이며 config --apply도 실행하지 않는다.
실제 설치된 Agent의 도움말과 CA 지문을 확인한 뒤 안내의 puppet ssl bootstrap --ca-fingerprint … --waitforcert 0을
실행한다. 서명 전 종료 오류는 CSR 대기일 수 있으며 전체 등록 성공으로 처리하지 않는다.
관리자가 Foreman 등록 호스트/고유 certname과 대조해 승인한 뒤 다시 bootstrap해 인증서를 받는다.
CA 개인키나 인증서 검증 우회, 모든 요청 무조건 자동 서명은 제공하지 않는다.
Agent 인증서 승인 API에 필요한 권한/Proxy 연동은 실제 설치에서 검증한다.

그 후 puppet agent --test --detailed-exitcodes의 0/2와 최신 Foreman Report를 확인하고 정기 실행을 활성화한다.
Foreman API용 PAT는 Agent mTLS를 대신하지 않으며 [등록 인증 설계](../docs/LOOKUP_AND_REGISTRATION.md)를 따른다.

## 중앙 파라미터와 이전 구성

Agent 입력의 deploy_env/team/dr_site/tls는 거부한다. 분류 파라미터는 Foreman에서 관리하고
examples/foreman-host.json은 등록 자동화의 논리 입력이며 현재 실행기의 JSON이나 실제 API 요청 형식은 아니다.
기존 Facts 파일은 자동 삭제하지 않는다. 중앙 파라미터/ENC 준비 후 옛 분류 키만 제거하고 다른 Facts는 보존한다.
기존 외부 CA나 Agent SSL 자료도 자동으로 삭제·재발급하지 않는다. [이전 기준](../docs/LOOKUP_AND_REGISTRATION.md)과
[장애 대응](../docs/FAILURE_RUNBOOK.md)의 CA 신원·상태 보존을 따른다.

## user-data 최초 Foreman 등록

[user-data 등록 함수](../docs/USER_DATA_REGISTRATION.md)는 설치 실행기와 별도로 사용한다.
Shell은 `bootstrap/user-data/register.sh`를 source한 뒤 접속·노드·분류 값을 인자로 전달해 `foreman_register`를 호출한다. PAYLOAD는 함수 안에서 생성한다.
Go는 접속·노드·분류 값을 Config에 채워 `RegisterForeman(ctx, cfg)`를 호출한다. 두 구현은 POST를 한 번만 보낸다.
입력 파일·plan/apply·Agent 설치는 등록 함수의 실행 조건이 아니다.
[전체 변수/호출 예시](examples/register.sh)를 기존 user-data에 통합한다.

## 검증과 한계

```sh
bundle exec ruby tests/bootstrap_test.rb
bash tests/registration_test.sh
```

테스트는 repo/install 계획에 Bash+jq, config 계획에 Ruby만 사용한다. 11개 wrapper, 7개 OS×2개 CPU,
AL2 예외·전체 버전 pin·미정 값·CA/manual approval 정책·신뢰 지문·기존 비밀값/INI 보존·시간 제한을 검증한다.
실제 키 다운로드·패키지 설치·CA 생성·인증서 등록·서비스·TLS·Foreman/OpenVox 9 통합은 실행하지 않는다.

APT는 --no-remove와 임시 policy-rc.d로 postinst 시작을 억제한다. 기존 policy-rc.d는 덮어쓰지 않는다.
RPM scriptlet은 공급 패키지 정책에 따르므로 최초 등록 전에 서비스 상태를 확인한다.
기존 *-bootstrap.list가 있으면 .sources와의 중복을 검토·이전하기 전 저장소 적용을 차단한다.
파일 단위 원자 교체를 사용하지만 전체 설치 rollback이나 운영 중 무중단 업그레이드를 보장하지 않는다.

근거: [Foreman Installer](https://theforeman.org/manuals/5.0/index.html),
[OpenVox CA 초기화 예](https://theforeman.github.io/foreman-infra/bootstrap/),
[OpenVox Agent SSL bootstrap](https://docs.openvoxproject.org/openvox/9.x/man/ssl.html).

1단계부터 foreman_service_fqdn을 서버 입력 JSON에 지정하고 backend 인증서 SAN에도 포함한다.
동일 NLB의 8444 TCP Target Group은 client IP preservation을 끄고 동일 VM으로 돌아오는 경로를 검증한다.
8444는 NLB 전용 포트이며 서버의 별도 listener가 아니다.
