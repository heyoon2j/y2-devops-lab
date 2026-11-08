# Host Group과 Puppet Environment

## 기본 제안

공통 HA 관리 클러스터에서 Puppet Environment를 `development`, `production`으로 분리한다.
Host Group은 CSP만 표현하며, 개발·운영 표시는 계속 `deploy_env` Fact를 사용한다.
기존 초기 예시의 단일 코드 환경에서 개발 검증·운영 승격이 가능한 두 코드 환경으로 확장한다.
관리 클러스터까지 분리할지는 배포 전에 확정한다.

| Host Group | `deploy_env` Fact | 호스트의 Puppet Environment | 공통 Class |
| --- | --- | --- | --- |
| `aws` | `dev` | `development` | `role::base` |
| `aws` | `prd` | `production` | `role::base` |
| `gcp` | `dev` | `development` | `role::base` |
| `gcp` | `prd` | `production` | `role::base` |
| `kc` | `dev` | `development` | `role::base` |
| `kc` | `prd` | `production` | `role::base` |

Host Group은 3개이며 개발·운영별 하위 그룹은 만들지 않는다.
한 그룹에 두 코드 환경의 호스트가 함께 들어갈 수 있으므로 그룹의 Puppet Environment를
단일 값으로 고정하지 않고 호스트 등록 시 명시한다. Foreman에서 두 환경의 Classes를
가져와 `role::base`가 양쪽 환경에 연결되어 있는지 확인한다.

## 등록 입력

등록 템플릿/IaC의 논리 입력 예시는 다음과 같다. 실제 Foreman API 인자 이름은 아니다.

```text
HOST_GROUP=aws
DEPLOY_ENV=dev
PUPPET_ENV=development
PUPPET_SERVER=puppet.example.internal
PUPPET_CA_SERVER=puppet-ca.example.internal
CERTNAME=aws-dev-node-001.example.internal
```

`PUPPET_ENV`는 별도 Fact로 추가하지 않는다. Foreman 호스트 분류와 Agent 설정에 사용하는
코드 환경 입력값이다. `PUPPET_CA_SERVER`는 CA를 Compiler에서 분리하기 위한 접속값이다.
신뢰할 수 있는 IaC/등록 서비스가 환경 매핑을 결정하고 잘못된 조합은 등록 전에 거부한다.
나중에 노드가 보낸 Fact를 읽어 Foreman의 Puppet Environment를 자동 변경하지 않는다.

개발 노드 Agent 설정 예시는 다음과 같다. 호스트 등록·CA 신뢰 체인·인증서 발급은
별도로 준비해야 하며 이 설정만으로 등록이 완료되지는 않는다.

```ini
[main]
server = puppet.example.internal
ca_server = puppet-ca.example.internal
certname = aws-dev-node-001.example.internal

[agent]
environment = development
```

Foreman ENC가 반환하는 코드 환경과 Agent 설정을 일치시킨다.
공통 Role은 `development/dev`, `production/prd`만 허용한다.
이 검증은 잘못된 배정을 차단하기 위한 것이며 노드가 보낸 Fact를 인증 근거로 삼지 않는다.

## 코드 배포와 Hiera의 관계

```text
/etc/puppetlabs/code/environments/
├── development/    # 검증할 Git commit의 foreman-puppet/ 내용
└── production/     # 승인한 Git commit의 foreman-puppet/ 내용
```

두 코드 환경은 같은 디렉터리 구조를 가지지만 다른 Git commit을 배포할 수 있다.
저장소에서 파일을 중복 관리하지 않고 동일한 `foreman-puppet/` 하위 트리를 버전별로 배포한다.
`production`을 개발 작업 디렉터리로 symlink하지 않는다. 실제 코드 배포 자동화는 후속 단계다.

1. 변경 commit을 모든 Compiler의 `development`에 배포한다.
2. 개발 노드에서 Catalog·실제 적용·멱등성을 검증한다.
3. 승인한 동일 commit을 모든 Compiler의 `production`에 승격한다.
4. 문제가 있으면 이전 승인 commit으로 되돌린다.

Hiera는 선택된 코드 환경 안에서 `deploy_env`별 파일 → `common.yaml` 순으로 조회한다.
코드 환경은 코드 버전, Fact는 데이터 선택과 표시를 담당한다.

Puppet Environment 분리만으로 개발·운영의 보안 경계가 완성되지는 않는다.
완전한 신뢰·장애 격리가 필요하면 Foreman/Puppet/DB/CA 관리 클러스터도 분리하고,
등록 권한과 네트워크 접근을 분리한다. 이 경우에도 위 CSP와 코드 환경 매핑 규약은 유지한다.
