# 서버 Role 구성

Foreman 호스트에 아래 Role 중 하나를 배정한다. CSP Host Group은 aws/gcp/kc를 유지한다.
Role은 user-data의 논리 입력 PUPPET_ROLE을 등록 자동화가 Foreman Class로 배정하는 방식이며,
실제 등록 자동화는 아직 구현하지 않았다. 팀 Fact로 Role을 자동 선택하지 않는다.

| 서버 구분 | Foreman Class | puppet_managed (Boolean) | 포함 Profile |
| --- | --- | --- | --- |
| 기본 서버 | role::base | true | profile::base |
| 미관리 대상 서버 | role::unmanaged | false | 작업 Profile 없음 |
| DevOps 대상 서버 | role::devops | true | profile::base + profile::devops |
| 데이터인프라팀 서버 | role::data_infra | true | profile::base + profile::data_infra |

```text
site-modules/
├── role/manifests/                 # Foreman이 호스트에 배정하는 조합
│   ├── base.pp                    # 일반 서버의 공통 설정
│   ├── unmanaged.pp               # 미관리 분류, false 여부 검증
│   ├── devops.pp                  # 공통 + DevOps Profile
│   ├── data_infra.pp              # 공통 + 데이터인프라팀 Profile
│   └── gpu_svr.pp                 # 이전 GPU 예제 호환용; 신규 기본 선택 목록에서는 제외
└── profile/manifests/              # 실제 기능별 설정
    ├── base.pp                    # OS/환경 검증 + 패키지/예시 파일/서비스 정책
    ├── devops.pp                  # DevOps 확장 지점; 추가 작업 없음
    ├── data_infra.pp              # 데이터인프라 확장 지점; 추가 작업 없음
    ├── gpu_system.pp              # GPU 확장 지점; 추가 작업 없음
    └── management.pp              # Foreman puppet_managed 타입 검증
```

팀 Role 안에서 공통 Profile을 포함하므로 role::base를 추가로 배정하지 않는다.
현재 팀별 Profile은 빈 확장 지점이다. 팀별 설정이 확정되면 기능별 Profile을 만들어 조합한다.
팀 Role을 선택해도 SSH·NTP·GPU·DB·Hadoop 설정이 자동 추가되지는 않는다.
서비스 제어는 기존 Hiera 정책을 사용하며 팀별 정책 데이터 선택 계층은 아직 추가하지 않았다.
따라서 팀 Role을 만드는 것만으로 Hiera 서비스 정책이 팀별로 달라지지는 않는다.

## 최초 설정과 지속 관리

이 문서의 분류표는 최초 설정 완료 후의 상태다. 기본/팀 Role은 처음부터 해당 Role로 적용하고
지속 관리한다. 미관리 대상은 최초에 role::base/true로 공통 설정을 적용한 뒤
성공을 확인하고 role::unmanaged/false로 전환한다.
[Role별 최초 설정과 지속 관리](ROLE_LIFECYCLE.md)에 단계·실패 처리·공유 설정 구조를 정리했다.
자동 전환은 아직 구현하지 않았다.

## 미관리 대상

Foreman 호스트 파라미터에 Boolean puppet_managed=false를 지정하고 role::unmanaged를 배정한다.
전역 true를 상속한 채 unmanaged Role만 선택하면 컴파일을 실패시켜 분류 오류를 드러낸다.
false이면 이 프로젝트의 다른 Role이 실수로 함께 남아 있어도 작업 리소스를 선언하지 않는다.
다만 호스트당 Role 하나라는 규칙 자체를 코드가 강제하는 것은 아니다.

이전 설정을 삭제하거나 원복하지 않으며 Agent의 Facts/Report 수집도 중단하지 않는다.
외부 Class의 설정까지 차단하는 기능은 아니다. 자세한 정책은 [관리 제어](MANAGEMENT_CONTROLS.md)를 따른다.

## Facts 및 기존 GPU 예제

team 파라미터는 선택적인 소유 팀 표시다. 예를 들어 devops, data_infra를 사용할 수 있지만
Fact가 Role 배정이나 접근 권한의 근거가 되지는 않는다.
GPU 존재/MIG Facts도 관측값이며 Role을 자동 변경하지 않는다.

기존 role::gpu_svr와 관련 문서의 GPU 흐름 예제는 호환용으로 유지한다.
팀 Role에 GPU 기능이 필요하면 해당 팀 Profile에서 profile::gpu_system을 조합한다.
이때 gpu_svr Role을 추가 배정하지 않고 공통 리소스의 중복 소유를 피한다.

검증: tests/catalog_test.rb에서 팀 Role의 공통/팀 Profile 포함, Facts 독립성,
전체 제외, 미관리 Role의 Boolean 검증과 작업 리소스 부재를 확인한다.
