# 적용·제외와 서비스 실행 정책

## 1. 호스트 전체 적용 스위치

Foreman의 최상위 ENC 파라미터 `puppet_managed`를 Boolean으로 지정한다.
기본 관리 대상에는 Foreman 전역 파라미터 `true`, 제외할 호스트에는 호스트 파라미터
`false`를 두는 구성을 권장한다. 문자열 `"false"`와 Boolean `false`를 혼용하지 않는다.

```yaml
# ENC 결과의 구조 예시. 실제 Foreman API 요청 body가 아니다.
parameters:
  csp: aws
  puppet_managed: false
  puppet_exclude_reason: "다른 팀에서 직접 관리"
classes:
  role::gpu_svr: {}
environment: development
```

`profile::management`가 이 값을 검증한다. 누락/잘못된 타입은 컴파일 오류다.
현재의 모든 Role과 개별 Profile 및 service_control 모두 이 스위치를 따른다.
노드를 제외해도 Role 배정을 지울 필요는 없다. Role은 남기고 포함하는 설정을 건너뛴다. 미관리 전용 분류에는 [role::unmanaged](ROLES.md)를 사용할 수 있으며 이 Role은 false를 필수로 요구한다.
분류 자동화는 이 파라미터를 지정해야 하며, 실제 등록/API 자동화는 아직 구현하지 않았다.

| 값 | 동작 |
| --- | --- |
| `true` | Profile별 설정에 따라 리소스 선언 |
| `false` | 이 프로젝트의 파일·패키지·서비스 작업 리소스를 선언하지 않음 |

제외는 기존 설정 원복/삭제가 아니다. 이전 설정은 그대로 두며 Agent의 Facts/Report 흐름을
끄지 않는다. `puppet_exclude_reason`은 Foreman의 설명용 메타데이터로만 사용한다.
`puppet_managed`는 Fact나 Hiera 키로 정의하지 않고 Foreman에서 관리한다.
현재 구현의 스위치는 이 프로젝트 코드에 적용되며 임의로 추가한 외부 Class까지 자동 차단하지 않는다.
외부 Class도 동일한 진입 제어를 거쳐야 한다. 급한 로컬 중단/오프라인 Agent는 별도 절차가 필요하다.

최초 설정이 필요한 미관리 대상은 처음부터 false로 등록하지 않는다. Base 적용 성공 후
전환하는 [Role별 수명 주기](ROLE_LIFECYCLE.md)를 따른다. 전환 자동화는 아직 구현 전이다.

## 2. Profile별 스위치

아래는 실제 구현된 Hiera 키다.

```yaml
profile::base::manage: true
profile::packages::manage: true
profile::example_file::manage: false
profile::gpu_system::manage: true
profile::devops::manage: true
profile::data_infra::manage: true
profile::services::manage: true
profile::ssh::manage: false
```

`example_file::manage=false`이면 예시 파일/부모 디렉터리와 이전 node.conf 삭제까지 모두
관리 대상에서 빠진다. 이미 생성된 파일을 삭제하지 않는다.
`base::manage=false`이면 공통 검증·패키지·예시·services 조합을 건너뛴다.
GPU Profile은 현재 리소스가 없는 확장 지점이며 향후 자원은 `$enabled` 가드 안에 넣어야 한다.

전체 `puppet_managed=false`가 Profile의 `manage=true`보다 우선한다.
DNS/NTP의 예약 키는 해당 Profile이 아직 구현되지 않아 실제 동작과 연결되지 않았다.

## 3. 서비스별 정책

`profile::services` Class가 Hiera의 `units`를 받아 `profile::service_control` 정의 리소스를 만든다.
기본값은 빈 매핑 `{}`이므로 현재 일반 Role/GPU Role은 아무 서비스도 시작/중지하지 않는다.

```yaml
# 실제 서비스가 설치되고 운영 정책이 정해진 뒤 서비스 이름을 지정한다.
profile::services::units:
  example.service:
    manage: true
    state_policy: running
    change_action: none
    timeout: 60
```

이 예시는 해당 서비스가 중단되어 있으면 다음 적용에서 시작을 시도한다.
서비스를 설치하거나 부팅 시 enable 설정까지 변경하지는 않는다.
실제 서비스 이름·설치·권한은 별도 Profile에서 준비한다.

| 파라미터 | 허용값 / 기본값 | 의미 |
| --- | --- | --- |
| `manage` | Boolean, `true` | 단위별 전체 제어 스위치 |
| `state_policy` | `preserve`(기본), `running`, `stopped` | 현재 상태 보존 / 실행 보장 / 중지 보장 |
| `change_action` | `none`(기본), `reload`, `restart` | 관리 파일 변경 이벤트 시 실행할 작업 |
| `config_files` | 관리 중인 File 리소스의 경로 목록, 기본 `[]` | 변경 이벤트 및 선행 검증/순서 연결 |
| `timeout` | 1~3600초, 기본 60 | 각 반영/상태 변경 명령의 최대 대기 시간 |
| `systemctl` | 기본 `/usr/bin/systemctl` | 절대 경로. 테스트에서는 가짜 명령으로 대체 |

`state_policy=stopped`는 `change_action=none`만 허용한다.
reload/restart에는 비어 있지 않은 `config_files`가 필요하다.
config_files는 실제 선언된 `File` 리소스여야 하며 파일 Profile을 끄면 연관 서비스 정책도 함께 조정한다.

## 4. 변경 이벤트 연결 예시

실제 서비스 Profile에서 설정 파일의 검증·소유권·값을 정의한 뒤 다음처럼 연결할 수 있다.
아래는 helper의 설명용 예시다. 실제 [SSH Profile](SSH_PROFILE.md)은 drop-in과 검증기를 관리하며 기본 비활성이다.

```puppet
# File['/etc/ssh/sshd_config']는 해당 Profile에서 먼저 선언하고 validate_cmd 등으로 검증한다.
profile::service_control { 'ssh.service':
  state_policy => 'preserve',
  change_action => 'reload',
  config_files => ['/etc/ssh/sshd_config'],
  timeout => 60,
}
```

파일 경로를 `config_files`로 전달하면 내부 refresh Exec에만 subscribe 관계를 연결한다.
호출 측에서 정의 리소스 전체에 `notify`를 추가하지 않는다.
Class인 `profile::services`의 파라미터는 Hiera APL로 조회하지만 정의 리소스의 파라미터는
자동 APL이 아니므로 `units` 매핑 또는 호출 측 Profile이 명시적으로 전달한다.

| 상태 정책 | 현재 상태 | 변경 이벤트 발생 시 |
| --- | --- | --- |
| preserve | 실행 중 | 지정한 reload/restart 수행 |
| preserve | 중단 | 시작하지 않음 |
| running | 실행 중 | 지정한 reload/restart 수행 후 상태 확인 |
| running | 중단 | 새 설정으로 한 번 시작. 직후 불필요한 추가 reload/restart 없음 |
| stopped | 실행/시작 진행 중 | 중지 시도. reload/restart 금지 |

변경 이벤트가 없으면 reload/restart하지 않는다. 단 running/stopped 예외는 매 Agent 실행에서
상태가 다른 경우에만 start/stop을 시도한다. 실제 구현은 시간 제한이 있는 systemctl Exec과
상태 가드를 사용하며 `Service` 리소스를 일괄 생성하지 않는다.
서비스 패키지·boot enable/disable·지속적인 health check는 이 공통 기능에서 관리하지 않는다.

## 5. 실패와 제외의 의미

- 명령은 한 번 시도하며 실패 시 Report 오류로 남긴다. reload 실패를 restart로 전환하지 않는다.
- 설정 File 검증에 실패하면 종속된 반영/상태 작업도 건너뛴다.
- 반영 명령 실패 후에는 같은 실행의 후속 상태 변경도 수행하지 않는다.
- 변경 이벤트 기반 반영은 다음 실행에 파일이 그대로이면 자동 재시도되지 않는다.
  원인 수정·새 변경 이벤트 또는 승인된 수동 재반영으로 해결한다.
- Exec timeout은 기다리는 명령을 제한한다. systemd가 이미 받은 job까지 취소됨을 보장하지 않으므로
  실제 서비스의 TimeoutStartSec/TimeoutStopSec·실행 결과·남은 job도 별도로 확인한다.
- 제외/정책 변경은 새 Catalog가 Agent에 도착해야 효력이 있다. 캐시/네트워크 장애 정책도 함께 고려한다.
- Zabbix가 상시 감시·알림을 담당하며 Foreman API/Report 알림 자동화는 아직 구현 전이다.

## 6. 적용 순서와 검증

1. 기존 노드에 코드 배포 전 Foreman 전역 Boolean `puppet_managed=true`를 준비한다.
2. 제외할 호스트는 Boolean `false`와 사유를 지정한다.
3. 개발 코드 환경에 배포하고 소수 노드에서 제외 Catalog와 Report를 확인한다.
4. Profile별 manage와 서비스별 정책을 필요한 값만 설정한다. `units={}`가 기본이다.
5. 실제 OS의 서비스 이름·systemctl 경로·문법 검사·반영 명령을 검증한 뒤 확대한다.

```sh
bundle exec ruby tests/catalog_test.rb
bundle exec ruby tests/service_policy_test.rb
```

첫 테스트는 600개 기본 조합과 전체/Profile/서비스 제외·Boolean 검증·Hiera 정책 전달을 컴파일한다.
두 번째는 임시 파일과 가짜 systemctl에 Catalog를 실제 적용해 변경 이벤트·멱등성·상태 정책·
실패·시간 초과·검증 실패의 동작을 확인한다. 실제 /etc와 systemd 서비스는 변경하지 않는다.
실제 Foreman 연동 및 Ubuntu/Rocky에서의 서비스 검증을 대신하는 것은 아니다.
