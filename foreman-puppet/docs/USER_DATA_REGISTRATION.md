# user-data에서 변수로 Foreman 등록

호출자가 값을 준비하고 함수를 한 번 호출한다. 함수는 요청 JSON을 내부에서 만들고
`POST /api/hosts`를 한 번 전송한 뒤 성공/실패만 반환한다. 별도 입력 JSON·plan/apply·CLI는 없다.

```text
bootstrap/
├── user-data/register.sh       # Bash 변수 → jq로 요청 구성 → curl POST
├── user-data/go/register.go    # Go Config 변수 → json.Marshal → net/http POST
└── examples/register.sh        # 기존 user-data에 복사할 변수·호출 예시
```

## Shell 사용

[전체 호출 예시](../bootstrap/examples/register.sh)를 기존 user-data에 넣고 실제 값으로 변경한다.
함수 파일은 검토한 코드 아티팩트에서 노드에 사전 배치한다. Bash·curl·jq와 사내 CA 파일이 필요하다.
PAT를 SSM에서 가져오는 예시는 AWS CLI와 해당 파라미터/KMS 조회 권한이 별도로 필요하다.

```bash
set +x
set +a
source /opt/foreman-puppet/bootstrap/user-data/register.sh

FOREMAN_URL="https://foreman.dev.example.internal"
FOREMAN_CA_CERT="/etc/company-pki/ca.pem"
FOREMAN_USERNAME="bootstrap_dev"
FOREMAN_PAT=$(aws ssm get-parameter --name /foreman/dev/bootstrap-pat \
  --region ap-northeast-2 --with-decryption --output json |
  jq -er '.Parameter | select(.Type=="SecureString") | .Value') || exit 1

NODE_NAME="node.dev.example.internal"
ORGANIZATION_ID=1
LOCATION_ID=1
HOSTGROUP_ID=1
ENVIRONMENT_ID=1
ROLE_ID=1
PUPPET_PROXY_ID=1
PUPPET_CA_PROXY_ID=1
DEPLOY_ENV="dev"
TEAM=""
DR_SITE="primary"
PUPPET_MANAGED=true

foreman_register || exit 1
unset FOREMAN_PAT
```

`source`만 하면 API를 호출하지 않는다. `foreman_register` 호출 시 실제로 등록한다.
함수는 Bash 문법이므로 확장자가 .sh여도 Bash에서 실행한다. 함수 자체는 root나 Agent를 요구하지 않는다.

## Go 사용

[register.go](../bootstrap/user-data/go/register.go)의 패키지를 기존 초기화 프로그램에 포함한다.
아래 예시의 `token`은 호출자가 비밀 저장소에서 조회한 값이다. 함수는 비밀 저장소나 외부 명령을 호출하지 않는다.
Go 표준 라이브러리만 사용하며 Python·Ruby·Bash·curl·jq가 필요하지 않다.

```go
// registration은 bootstrap/user-data/go 패키지의 import 별칭이다.
// token은 호출자가 비밀 저장소에서 조회한 PAT 변수다.
cfg := registration.Config{
    URL: "https://foreman.dev.example.internal",
    CACert: "/etc/company-pki/ca.pem",
    Username: "bootstrap_dev", Token: token,
    Name: "node.dev.example.internal",
    OrganizationID: 1, LocationID: 1, HostgroupID: 1,
    EnvironmentID: 1, RoleID: 1, ProxyID: 1, CAProxyID: 1,
    DeployEnv: "dev", Team: "", DRSite: "primary", Managed: true,
}
if err := registration.RegisterForeman(ctx, cfg); err != nil {
    return err
}
```

기존 프로그램에 컴파일해서 배포하므로 노드에 Go 컴파일러를 설치할 필요는 없다.

## 입력 값

| Shell 변수 | Go Config 필드 | 값/용도 |
| --- | --- | --- |
| FOREMAN_URL | URL | Foreman HTTPS origin |
| FOREMAN_CA_CERT | CACert | 사내 CA PEM 경로 |
| FOREMAN_USERNAME | Username | 등록 전용 계정 |
| FOREMAN_PAT | Token | 호출자가 비밀 저장소에서 읽은 PAT. 원문을 코드/user-data에 저장하거나 export하지 않음 |
| NODE_NAME | Name | Agent certname과 일치하는 고유 FQDN |
| ORGANIZATION_ID | OrganizationID | 실제 조직 ID |
| LOCATION_ID | LocationID | 실제 위치 ID |
| HOSTGROUP_ID | HostgroupID | aws/gcp/kc Host Group ID. 그룹에서 csp 파라미터 상속 |
| ENVIRONMENT_ID | EnvironmentID | dev는 development, prd는 production의 실제 ID |
| ROLE_ID | RoleID | 단일 role::base/unmanaged/devops/data_infra Puppet Class ID |
| PUPPET_PROXY_ID | ProxyID | Puppet 기능 Smart Proxy ID |
| PUPPET_CA_PROXY_ID | CAProxyID | Puppet CA 기능 Smart Proxy ID |
| DEPLOY_ENV | DeployEnv | dev/prd. sandbox는 TODO |
| TEAM | Team | 선택적 팀. 빈 문자열이면 호스트 파라미터 생략 |
| DR_SITE | DRSite | primary/secondary 또는 빈 문자열(생략) |
| PUPPET_MANAGED | Managed | Boolean. role::unmanaged는 false로 지정 |

예시의 1은 실제 예약 ID가 아니다. 관리자가 조직·위치·그룹·환경·Role·Proxy ID와 연결 관계를 확인해 전달한다.
환경 이름·Role 이름·CSP를 중복으로 받거나 ID를 자동 조회하지 않는다. 그룹/환경/Role을 함수가 만들지도 않는다.
team/dr_site를 생략하면 상위 설정이 상속될 수 있으며, 명시적인 null 상속 차단 기능은 없다.

## API 동작과 범위

- `managed=false/build=false`는 기존 인스턴스의 OS 프로비저닝을 하지 않는다는 뜻이다.
  시스템 설정 관리 여부는 별도 Boolean 파라미터 puppet_managed로 전달한다.
- `overwrite=false`를 명시한다. 동일 이름이 있으면 서버가 충돌을 반환하도록 하고 기존 정책을 수정하지 않는다.
  GET/PUT/PATCH/DELETE, 기존 신원 대조·정책 검증·자동 재시도는 수행하지 않는다.
- HTTP 2xx면 Shell은 종료 코드 0, Go는 nil을 반환한다. 그 외에는 실패한다.
  2xx는 API 요청 수락을 뜻하며 최종 ENC·인증서·첫 Puppet 적용 성공을 보장하지 않는다.
- 응답 유실·시간 초과·서버 오류에는 이미 생성된 호스트가 있을 수 있다. 관리 측에서 확인하고 재호출 여부를 정한다.
  함수가 자동으로 다시 POST하지 않는다. 이름 재사용 시 기존 호스트/인증서 정리는 별도 절차다.
- HTTPS CA/호스트명을 검증하고 리다이렉트는 따르지 않는다. PAT·응답 본문을 로그에 출력하지 않는다.
  Shell은 curl 인증 설정을 stdin 파이프로, Go는 요청 헤더를 메모리에서 전달한다.
- 토큰 발급·비밀 조회는 호출자가 담당한다. 등록 전용 계정의 신규 생성/파라미터/Class 배정 권한을 제한하고
  만료일 있는 PAT를 사용한다. 사내 CA 파일은 노드에 미리 준비한다.

등록 후 관리 측에서 ENC를 확인하고 Agent CSR 승인 → 첫 Catalog/Report를 검증한다.
인스턴스 신원 검증을 포함한 API Gateway+Lambda 공통 등록 서비스는 고도화 TODO다.
현재 함수는 입력값을 검증하는 API 호출 도구이며 클라우드 신원을 인증하는 서비스가 아니다.

## 검증

개발 머신에서 Go·Bash·curl·jq로 실행한다. 노드에는 사용하는 구현의 실행 환경만 필요하다.

```sh
bash tests/registration_test.sh
```

두 구현을 같은 HTTPS 모의 서버로 검증한다. 한 번의 POST·overwrite=false·Puppet 플러그인 요청·Boolean·
선택적 team, 중복/권한/서버 오류, 리다이렉트·신뢰하지 않는 CA 거부, PAT 비노출을 확인한다.
실제 Foreman API/RBAC·ENC 연동은 개발 서버에서 추가 확인해야 한다.
