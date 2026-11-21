# CSP별 시스템 정책과 팀 표시

## 관리 대상과 현재 구현 범위

관리 대상은 Ubuntu 20.04·22.04·24.04·26.04, Rocky Linux 8·9, Amazon Linux 2·2023로 해석한다.
현재 코드는 이 OS/아키텍처 Facts로 Catalog를 컴파일하는 기준을 검증한다.
실제 이미지의 Facts 값, 각 OS의 Puppet Agent 패키지 가용성·서비스 동작은 설치 단계에서
검증해야 한다. 컴파일 성공을 배포판 전체의 런타임 호환성 보장으로 해석하지 않는다.
관리 서버의 지원 OS는 Foreman/Puppet Server 버전에 맞춰 별도로 선택한다.

## CSP 전달과 Hiera 우선순위

Host Group 이름을 Puppet이 자동으로 알아낸다고 가정하지 않는다.
Foreman Host Group Parameters에서 아래 값을 설정해 ENC의 최상위 파라미터로 전달한다.

| Host Group | ENC 파라미터 | 값 |
| --- | --- | --- |
| `aws` | `csp` | `aws` |
| `gcp` | `csp` | `gcp` |
| `kc` | `csp` | `kc` |

Puppet 공통 Profile은 `csp`가 누락되거나 허용값이 아니면 컴파일을 거부한다.
이는 Foreman 분류 정보이며 노드가 직접 제출하는 CSP Fact를 추가한 것이 아니다.
Host Group에는 여전히 Role을 배정하지 않고 호스트별 Role은 user-data 등록 입력으로 정한다.

```text
AWS 개발 노드: csp=aws / deploy_env=dev
    ↓ 키별로 먼저 발견한 값 사용
data/csp/aws/dev.yaml     # CSP + 환경 (필요할 때 생성; 현재 파일 없음)
    ↓ 없으면
data/csp/aws.yaml         # CSP 공통값
    ↓ 없으면
data/deploy_env/dev.yaml  # 환경 공통값
    ↓ 없으면
data/common.yaml         # 전체 공통값
```

존재하지 않는 파일은 건너뛴다. 같은 키가 여러 곳에 있으면 위 계층이 우선한다.
배열도 별도 merge 설정 없이는 통째로 교체한다.
CSP 기본값보다 환경별 예외가 우선해야 한다면 `data/csp/<csp>/<env>.yaml`에 명시한다.

## 중앙 환경·팀·DR 파라미터

deploy_env/team/dr_site는 Foreman 호스트 파라미터다. 최초 user-data 등록 입력으로 전달하고
이후에는 Foreman 웹/API에서 관리한다. team 미정은 null/미설정으로 처리하며 Role을 자동 선택하지 않는다.
현재 Hiera에는 팀별·DR별 계층을 추가하지 않는다. OS·Arch·GPU/MIG만 자동 수집 Facts다.

## DNS / NTP 정책

| CSP | 정책 |
| --- | --- |
| AWS | 기존 DNS/NTP 설정 유지. 관련 파일·패키지·서비스를 관리하지 않음 |
| GCP | 기존 DNS/NTP 설정 유지. 관련 파일·패키지·서비스를 관리하지 않음 |
| KC | 향후에만 관리. 현재 주소와 백엔드가 미정이므로 적용 비활성 |

`data/csp/kc.yaml`에 다음 예약 데이터 계약을 두었다.

```yaml
profile::dns::manage: false
profile::dns::servers: []
profile::dns::search_domains: []
profile::ntp::manage: false
profile::ntp::servers: []
```

아직 DNS/NTP Profile은 구현하지 않았다. 이 키들은 후속 구현의 입력 형식이며 지금 값을
바꾼다고 설정이 적용되지는 않는다. 미정 주소를 임시 IP나 빈 설정 파일로 배포하지 않는다.
후속 Profile은 KC에서만 켤 수 있도록 검증하고, 활성화 시 필수 주소가 비어 있으면
컴파일을 거부하도록 구현한다. 비활성화는 리소스를 선언하지 않는 의미로 설계한다.

DNS는 Ubuntu의 systemd-resolved/netplan 및 Rocky의 NetworkManager 등 실제 이미지의
관리 주체를 확인한 후 구현한다. `/etc/resolv.conf`만 덮어써서 다른 서비스가 되돌리는
구성을 만들지 않는다. NTP 역시 기존 chrony/timesyncd와 서비스 충돌 여부를 확인한다.

## 제공된 설정 목록의 Profile 분리 계획

SSH는 기본 비활성으로 구현했으며 나머지는 후속 계획이다.

| 항목 | 제안 Profile | 필요한 정책·입력 |
| --- | --- | --- |
| cloud.cfg | `profile::cloud_init` | 적용할 키, CSP 차이, 네트워크·키 재생성 등 cloud-init 소유 범위 |
| sshd_config (기본 비활성 코드 구현) | `profile::ssh` | Banner·패스워드 인증·root 로그인, 조합 검증 및 reload. 포트는 관리하지 않음 |
| DNS | `profile::dns` | KC 주소·검색 도메인·실제 resolver 백엔드 |
| NTP | `profile::ntp` | KC 시간 서버·기존 데몬·재시작 정책 |
| yum/dnf·apt 소스 | `profile::repositories` | OS 버전·CSP별 저장소 주소·서명키·기존 저장소 유지 범위 |
| authorized_keys | `profile::authorized_keys` | 대상 사용자·공개키·기존 키 유지/정리 범위. 개인키는 관리 데이터에 넣지 않음 |
| Zabbix | `profile::zabbix` | Agent 종류·버전·서버 주소·호스트 식별자·TLS 방식 |
| Puppet | `profile::puppet_agent` | 서버·코드 환경·실행 주기·첫 등록/정기 실행 구분. 인증서 설정은 후속 단계 |

최초 등록 전 Puppet 접속값과 Foreman deploy_env/team/dr_site 파라미터를 등록 자동화에서 준비한다.
Puppet의 사후 관리 Profile에만 넣어 첫 접속 자체가 불가능해지는 순환 의존을 만들지 않는다.
DB/Hadoop/GPU용 추가 시스템 정책은 필요할 때 별도 Profile로 조합한다.
모든 서비스 설정 Profile은 [서비스 설정 변경 정책](SERVICE_CHANGE_POLICY.md)에 따라
검증 후 실제 변경 시에만 필요한 reload/restart를 수행한다. 주기적인 서비스 자동 시작과
상태 알림은 Puppet의 기본 책임으로 넣지 않고 Zabbix의 감시와 구분한다.

## 검증

Catalog 테스트는 8개 OS 버전·2개 아키텍처·3개 CSP·2개 환경·2개 Role·5개 GPU 상태의
960개 조합을 확인한다. 별도 임시 데이터에서 4단계 Hiera 우선순위와 CSP 누락/오류도 검증한다.
실제 DNS/NTP·SSH·저장소·Zabbix 설정 적용 시험을 수행한 것은 아니다.

SSH의 요청값과 구현·검증 범위는 [SSH Profile](SSH_PROFILE.md)을 따른다.
