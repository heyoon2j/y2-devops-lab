# Puppet 코드 구성

## 디렉터리

```text
foreman-puppet/                         # Puppet 코드 환경 하나의 루트
├── README.md                           # 전체 아키텍처와 등록 입력·Facts 규약
├── environment.conf                    # manifest 위치와 모듈 검색 경로
├── manifests/                          # 환경에 진입할 때 읽는 Puppet 선언
│   └── site.pp                         # 노드 기본 선언; Class 배정은 Foreman ENC 담당
├── hiera.yaml                          # 설정 데이터 조회 순서 정의
├── data/                               # 코드에서 분리한 설정값(YAML)
│   ├── common.yaml                     # 모든 환경에 공통인 기본값
│   └── deploy_env/                     # deploy_env Fact에 따른 환경별 데이터
│       ├── dev.yaml                    # 개발 환경의 덮어쓰기 값
│       └── prd.yaml                    # 운영 환경의 덮어쓰기 값; 현재 공통값 상속
├── site-modules/                       # 이 프로젝트가 직접 작성한 Puppet 모듈
│   ├── role/                           # 서버의 목적을 묶는 모듈
│   │   └── manifests/base.pp           # role::base: 공통 Profile 묶음
│   └── profile/                        # 패키지 등 기능별 설정을 묶는 모듈
│       ├── manifests/                  # 실제 Puppet Class 정의(.pp)
│       │   ├── base.pp                 # 환경·OS·아키텍처 검증 및 하위 Profile 포함
│       │   ├── packages.pp             # Hiera에서 받은 패키지 설치 목록 적용
│       │   └── node_info.pp            # /etc/foreman-puppet/node.conf 관리
│       └── templates/                  # 노드별 값으로 렌더링할 파일 원본
│           └── node.conf.epp           # 환경·OS·아키텍처를 기록하는 템플릿
├── docs/                               # 상세 운영·설계 설명
│   ├── PUPPET_CODE.md                  # 이 문서: 디렉터리·Class·Hiera 사용법
│   ├── ENVIRONMENTS.md                 # Host Group과 Puppet 코드 환경 매핑
│   └── HA_AND_CERTIFICATES.md          # 개발 단일 서버 → 운영 HA 및 사내 인증서
├── Gemfile                             # 로컬 검증에 필요한 Ruby gem 목록
├── Gemfile.lock                        # 검증용 gem 버전 고정
└── tests/                              # 실제 설정 적용 없이 코드 검증
    └── catalog_test.rb                 # Catalog 컴파일·Hiera·입력 검증 테스트
```

`foreman-puppet/`의 내용이 Puppet 코드 환경 하나의 루트다.
Puppet Server의 `/etc/puppetlabs/code/environments/development/`와
`/etc/puppetlabs/code/environments/production/`에 각각 검증할 코드와 승인된 코드를 배포한다.
저장소 전체를 이 경로에 복사하지 않고 이 하위 디렉터리의 내용만 배포한다.
Puppet Environment는 코드 버전 선택이고 `deploy_env`는 호스트의 환경 Fact다.
등록 단계에서 두 값을 함께 지정하고, 공통 Role이 매핑 일치 여부를 검증한다.
상세 매핑은 [Host Group과 코드 환경](ENVIRONMENTS.md)을 참고한다.

## Site와 Foreman 분류

`manifests/site.pp`에는 기본 노드 선언만 둔다. Foreman ENC가 적용할 Class를 결정한다.
Foreman에서 `aws`, `gcp`, `kc` 각각에 공통 Role인 `role::base`를 배정한다.
Class가 배정되지 않은 호스트의 Catalog에는 이 프로젝트의 관리 리소스가 없다.

| Host Group | Foreman에 배정할 Class | Puppet Environment |
| --- | --- | --- |
| `aws` | `role::base` | 호스트별 `development` 또는 `production` |
| `gcp` | `role::base` | 호스트별 `development` 또는 `production` |
| `kc` | `role::base` | 호스트별 `development` 또는 `production` |

CSP 이름을 Fact로 추가하거나 `deploy_env`로부터 Host Group을 추정하지 않는다.
현재 Hiera는 CSP별 데이터를 선택하지 않는다. CSP별 정책이 필요하면 Foreman의 신뢰할 수
있는 분류 정보를 코드에 전달하는 규약을 먼저 확정한다.

## Classes

| Class | 책임 |
| --- | --- |
| `role::base` | Foreman에서 배정하는 공통 서버 역할. `profile::base` 포함 |
| `profile::base` | 환경·OS·아키텍처 검증 및 하위 Profile 포함 |
| `profile::packages` | Hiera의 패키지 목록을 `ensure => installed`로 관리 |
| `profile::node_info` | `/etc/foreman-puppet/node.conf`에 환경·Puppet 코드 환경·OS·아키텍처 기록 |

`deploy_env`가 `dev/prd`가 아니거나, Ubuntu 24.04가 아니거나,
`os.architecture`가 `amd64/arm64`가 아니면 공통 Role의 Catalog 컴파일을 실패시킨다.
또한 `development ↔ dev`, `production ↔ prd` 매핑이 맞지 않거나 다른 코드 환경이면 실패한다.
이로써 잘못된 환경 Fact가 공통값으로 조용히 대체되는 것을 방지한다.

`gpu.present`와 `gpu.mig.configured`는 Foreman의 관측 정보다. 기본 Role은 이 Fact의 유무와 값에
따라 MIG를 생성·삭제하거나 GPU 드라이버를 변경하지 않는다. 수집기는 후속 단계에서 구현한다.
`deploy_env` Fact 파일도 user-data 소유로 유지한다.

## Host Group에 여러 Role을 배정할 수 있는가?

기술적으로 가능하다. Foreman은 Host Group에 여러 Puppet Classes를 연결할 수 있고,
`role::*`는 Puppet의 일반 Class에 붙인 명명 규약이다. 노드당 Role 하나는 설계 관례이며
Foreman이나 현재 코드가 자동으로 강제하는 제약은 아니다.

그러나 Host Group에 배정한 Classes는 그 그룹에 속한 호스트들에 공통 적용된다.
`aws` 그룹에 `role::web`과 `role::database`를 모두 넣으면 개별 웹/DB 서버를 구분하는
분류가 아니라 해당 그룹의 호스트가 두 역할을 모두 받는 분류가 된다.

현재는 세 CSP 그룹에 `role::base`만 공통 배정한다. 향후 웹·GPU 등 서로 다른 역할을
도입할 때는 그룹에 공통 `profile::base`를 두고 호스트에 최종 Role 하나를 배정하는
방식으로 전환할 수 있다. 이때 그룹에서 기존 `role::base`를 제거하고 전환한다.
최종 Role도 `profile::base`를 `include`하면 Class는 한 번만 평가된다.

여러 기능이 필요한 노드는 최종 Role 하나 안에서 필요한 Profiles를 조합한다.
아래는 설명용 예시이며 해당 Class/Profiles는 아직 구현하지 않았다.

```puppet
class role::gpu_worker {
  include profile::base
  include profile::gpu_runtime
  include profile::monitoring
}
```

서로 다른 Classes가 같은 리소스를 중복 선언하거나 서비스 설정·파라미터를 다르게
관리하면 충돌할 수 있다. 여러 Role을 배정할 경우에는 최종 Catalog를 검증해야 한다.

- [Puppet: Configuring roles and profiles](https://help.puppet.com/core/current/Content/PuppetCore/configuring_roles_and_profiles.htm)
- [Foreman: Host Group Puppet Classes API](https://apidocs.theforeman.org/foreman/2.3/apidoc/v2/hostgroup_classes.html)

## Hiera

조회 우선순위는 다음과 같다.

1. `data/deploy_env/%{facts.deploy_env}.yaml`
2. `data/common.yaml`

Class의 자동 파라미터 조회(APL)로 `profile::packages::packages`를 주입한다.
동일한 키는 첫 번째로 발견한 값을 사용한다. 배열도 통째로 교체하므로,
환경별 파일에서 패키지 목록을 덮어쓸 때는 필요한 공통 패키지를 모두 포함한다.

| `deploy_env` | 최종 패키지 목록 | 출처 |
| --- | --- | --- |
| `dev` | `ca-certificates`, `curl`, `jq` | `dev.yaml`의 초기 예시 정책 |
| `prd` | `ca-certificates`, `curl` | 비어 있는 `prd.yaml`을 지나 `common.yaml` 조회 |

패키지 버전은 고정하지 않으며 패키지 저장소 접근은 배포 환경에서 준비한다.
이미 설치된 패키지를 최신 버전으로 강제 업그레이드하거나, 목록 밖의 패키지를 제거하지 않는다.
위 패키지 목록은 초기 기준이므로 실제 운영 정책에 맞게 Hiera에서 조정한다.
Hiera 데이터에 등록 토큰이나 비밀번호를 저장하지 않는다.

## Foreman 연결 순서

1. 먼저 개발 관리 서버 1대에 Foreman·Puppet Server·Smart Proxy·DB를 설치하고,
   사내 인증서 신뢰와 ENC/Facts/Report 연동을 준비한다.
2. 개발 단계에서는 development 코드를 배포하고 Classes를 가져온다.
   운영 HA 구축 시 production을 배포하고 해당 환경의 Classes도 가져온다.
3. `aws/gcp/kc` Host Group에 공통 `role::base`를 배정한다.
   Host Group의 Puppet Environment는 비워 두고 등록 시 호스트별로 명시한다.
4. Profile Class는 Role을 통해 포함한다. Hiera로 관리할 파라미터의 Foreman override는 비워 둔다.
5. 등록 절차에서 호스트의 Puppet Environment와 Agent 코드 환경을 맞추고,
   user-data로 환경 Fact 생성, Agent 설치와 인증서 승인 절차를 진행한다.
6. 개발 노드에서 첫 적용 및 두 번째 적용의 멱등성을 확인한 뒤 운영에 적용한다.

## 로컬 검증

Ruby와 Bundler가 있는 개발 환경에서 실행한다. 검증 기준 Puppet 버전은 8.10.0이며
의존성은 `Gemfile.lock`으로 고정한다. 실제 배포 버전의 호환성은 별도로 확인한다.

```sh
cd foreman-puppet
bundle install
bundle exec ruby tests/catalog_test.rb
```

검증은 임시 코드 환경을 만들고 Catalog만 컴파일한다. 로컬 OS의 패키지나 `/etc`는 변경하지 않는다.
다음 항목을 확인한다.

- `dev/prd`, `amd64/arm64`, GPU 존재·MIG 구성 상태 조합에서 Hiera와 EPP 렌더링
- GPU/MIG Facts가 없는 초기 노드의 컴파일
- Foreman Class가 배정되지 않은 노드의 무변경 Catalog
- 환경 Fact 누락·잘못된 값·경로 형태 값, 지원하지 않는 OS·버전·아키텍처의 컴파일 거부
- Fact와 Puppet 코드 환경의 불일치 및 지원하지 않는 코드 환경 거부

실제 Foreman API 등록, GPU/MIG 하드웨어 탐지, Ubuntu Agent의 리소스 적용·멱등성은
이 컴파일 검증에 포함되지 않는다.
