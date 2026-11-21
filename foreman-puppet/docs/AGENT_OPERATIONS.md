# Agent 실행 설정과 운영 정책 초안

이 문서는 설정 제안이다. Agent 설치·puppet.conf 배포 또는 AWS 리소스 생성은 아직 하지 않는다.
실제 설치할 Puppet/OpenVox 버전을 확정한 후 옵션과 지원 동작을 확인한다.

## 실행 방식

| 방식 | 용도 | 주의점 |
| --- | --- | --- |
| Agent 서비스 | 정기적인 설정 유지. 이 프로젝트의 권장 기본 |
| 수동 `puppet agent --test` | 최초 적용·승인한 긴급 변경·진단 | 기존 서비스 실행과 중복 호출하지 않고 실행 lock 확인 |
| `--noop` | 예상 리소스 변경 확인 | 실제 적용 성공 판정 아님. 리소스별 noop override와 검증 명령의 동작도 검토 |
| cron/systemd timer에서 일회 실행 | 서비스 대신 사용할 수 있는 대안 | Agent 서비스와 스케줄러를 중복 운영하지 않음 |

## 접속과 노드 신원

- `server`: 실제 Compiler EC2 이름 대신 Puppet LB의 논리 DNS 이름
- `ca_server`: Compiler pool과 분리된 CA endpoint. 외부 CA 직접 발급 모델이면 별도 절차 적용
- `certname`: 인스턴스 수명 주기에 맞춘 고유하고 안정적인 노드 신원. 이미지에 복제된 개인키 사용 금지
- `environment`: 개발 `development`, 운영 `production`. Foreman ENC 분류와 일치
- `report_server`: 특별한 Report 경로를 설계하지 않으면 기본값 사용. Foreman URL로 임의 변경하지 않음

Agent는 Puppet Server에 Report를 보내고, Server의 연동이 Foreman에 전달하는 기본 흐름이다.
개발·운영은 같은 설정 구조와 운영 절차를 사용하되 endpoint·코드 환경·신뢰 자료는 분리한다.

## 주요 실행 옵션

| 설정 | 권장 초안 | 고려할 점 |
| --- | --- | --- |
| `runinterval` | `30m` | 초기 기준. 실제 실행 시간과 1,000~2,000대 부하를 측정해 조정 |
| `splay` | `true` | Agent 서비스 시작/재시작 후 첫 실행을 분산. 매 실행마다 새 난수를 주는 것으로 해석하지 않음 |
| `splaylimit` | `30m` | 최초 분산 대기 상한. 서비스 재시작 시 다시 계산되며 최초 등록 batch와 별도 설계 |
| `runtimeout` | 유한한 상한 설정, 실제 값은 실측 후 확정 | 전체 Agent 실행의 시간 제한. 리소스별 명령·systemd 제한도 필요 |
| `http_connect_timeout`, `http_read_timeout` | 유한한 상한과 LB 설정을 함께 검토 | 네트워크 지연·실제 컴파일 시간보다 지나치게 짧게 잡지 않음 |
| `report` | `true` | 등록/적용 결과 확인에 필요. 미수신도 별도 감시 |
| `pluginsync` | `true` | 커스텀 Facts/타입의 배포 방식과 연계 |
| `ignore_plugin_errors` | `false` 유지 | 플러그인 동기화 실패를 무시하고 오래된 Facts로 진행하지 않음 |
| `usecacheonfailure` | 현재 프로젝트 권장 초안은 `false` | 새 Catalog 실패 시 과거 Catalog 적용을 막음. 기본값과 다르므로 설치 시 명시·검증 |
| `use_cached_catalog` | `false` | 매번 새 Catalog 요청과 Facts 전달. 캐시만 쓰는 모드로 고정하지 않음 |
| `show_diff` | 기본 운영 초안은 `false` | 설정 내용이 로그/Report로 노출되지 않도록 함. 승인한 비밀값 없는 진단에서만 검토 |
| `waitforcert`, `maxwaitforcert` | 첫 등록의 대기와 재시도에 상한 | CA 모델 확정 후 설정. 무기한 기다리는 부트스트랩 방지 |
| `noop` | 정기 실제 적용에서는 `false` | 검증 때 일시 활성화. 전체 제외 정책의 대체로 사용하지 않음 |

`usecacheonfailure=false`이면 새 Catalog를 받지 못할 때 과거 Catalog를 대신 적용하지 않는다.
기존 설정/서비스는 그 상태로 남지만 서버 연결 복구 전 설정 이탈을 자동 복구하지 못할 수 있다.
`true`는 마지막 Catalog를 계속 적용할 수 있으나 오래된 정책·제외 이전 설정을 재적용할 수 있다.
어느 방식이든 중앙 제외 정책의 변경은 통신이 끊긴 Agent에 즉시 전파되지 않는다.
긴급한 로컬 중단은 별도의 Agent disable 절차와 모니터링 점검 기간을 연계한다.

## 파일 형태 예시

아래는 핵심 항목의 구조이며 완성된 설치 설정은 아니다.
인증서 경로·시간 제한·배포 엔진별 옵션과 bootstrap은 별도로 확정한다.

```ini
[main]
server = puppet-dev.example.internal
ca_server = puppet-ca-dev.example.internal
certname = <unique-node-certname>

[agent]
environment = development
runinterval = 30m
splay = true
splaylimit = 30m
report = true
pluginsync = true
ignore_plugin_errors = false
usecacheonfailure = false
use_cached_catalog = false
show_diff = false
noop = false
```

초기 user-data는 준비된 인증과 서버 연결로 최초 1회 적용을 제어한 뒤 서비스를 시작한다.
서비스의 splay가 최초 부트스트랩 완료 판정까지 무기한 늦추는 구조로 만들지 않는다.
정기 실행과 일회 실행은 같은 lock을 고려하며, 실행 시간이 길다고 중복 작업을 계속 쌓지 않는다.

## 서비스 감시와의 구분

이 설정은 Puppet Agent 자체의 실행 정책이다. SSH/Zabbix/NTP 등의 생존을 매 주기
무조건 보장한다는 의미가 아니다. 각 서비스의 preserve/running/stopped와 변경 시
none/reload/restart 정책은 별도로 구현하고 상시 감시는 Zabbix에 둔다.
서비스별 예외는 [관리 제어](MANAGEMENT_CONTROLS.md)의 공통 코드로 구현했다.
기본 units는 비어 있다. SSH 파일·검증·서비스 연결은 [SSH Profile](SSH_PROFILE.md)로 구현했고 기본 비활성이다. 패키지 설치와 실제 OS 검증은 별도다.

## 참고

- [Agent 설정 개요](https://help.puppet.com/core/current/Content/PuppetCore/settings_agents_all_nodes.htm)
- [설정 전체 Reference](https://help.puppet.com/core/current/Content/PuppetCore/Markdown/configuration.htm)
- 옵션 동작은 저장소의 Puppet 8.10.0 코드에서도 확인했으나 배포 버전의 실환경 검증은 별도다.
