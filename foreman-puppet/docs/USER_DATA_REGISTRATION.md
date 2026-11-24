# user-data Foreman 등록

호출자가 접속·노드·분류 값을 함수 인자로 전달하면 함수 안에서 JSON을 만든다.
함수는 POST /api/hosts를 한 번 보내고 성공/실패만 반환한다.

- [Shell 함수](../bootstrap/user-data/register.sh): 함수 인자 → jq로 JSON 생성 → curl
- [Go 함수](../bootstrap/user-data/go/register.go): Config 입력 → json.Marshal → net/http
- [전체 Shell 예시](../bootstrap/examples/register.sh): 변수 설정·PAT 조회·함수 호출

## Shell

Bash에서 파일을 source하고, 같은 프로세스 안에서 함수를 호출한다. source만으로 API가 호출되지는 않는다.
`token`은 비밀 저장소에서 조회한 PAT 변수다. 아래 숫자 ID는 실제 Foreman ID로 바꾼다.

```bash
set +x
set +a
source /opt/foreman-puppet/bootstrap/user-data/register.sh
foreman_register \
  "$FOREMAN_URL" "$FOREMAN_CA_CERT" "$FOREMAN_USERNAME" "$token" \
  "$NODE_NAME" "$ORGANIZATION_ID" "$LOCATION_ID" \
  "$HOSTGROUP_ID" "$ENVIRONMENT_ID" "$ROLE_ID" \
  "$PUPPET_PROXY_ID" "$PUPPET_CA_PROXY_ID" \
  "$DEPLOY_ENV" "$PUPPET_MANAGED" "${TEAM:-}" "${DR_SITE:-}" || exit 1
```

인자 순서는 접속 정보 4개 → 노드/조직/위치 → 그룹/환경/Role → Proxy 2개 → deploy_env/관리 여부 → 선택 team/dr_site다.
앞의 14개는 필수이며 마지막 두 값은 생략하거나 빈 문자열을 전달할 수 있다.
PAT 원문을 코드·user-data에 적거나 export하지 않고 set +x 상태에서 전달한다.
함수는 Bash·curl·jq가 필요하며 PAT는 curl stdin으로 전송한다. 전체 예시의 AWS CLI는 호출자가 SSM PAT를 조회하는 부분이다.

## Go

기존 Go 초기화 프로그램에 패키지를 포함하고 Config로 입력을 전달한다. JSON 생성은 함수 안에서 처리한다.

```go
cfg := registration.Config{
    URL: "https://foreman.dev.example.internal",
    CACert: "/etc/company-pki/ca.pem",
    Username: "bootstrap_dev", Token: token,
    Name: "node.dev.example.internal",
    OrganizationID: 1, LocationID: 1, HostgroupID: 1,
    EnvironmentID: 1, RoleID: 1, ProxyID: 1, CAProxyID: 1,
    DeployEnv: "dev", Managed: true, Team: "", DRSite: "primary",
}
if err := registration.RegisterForeman(ctx, cfg); err != nil {
    return err
}
```

Go 표준 라이브러리만 사용하며 별도 CLI·Bash·Ruby를 호출하지 않는다.

## 입력과 생성되는 요청

호출자는 아래 값의 실제 ID와 정책을 준비한다. Shell 함수의 jq와 Go 함수의 json.Marshal이 요청 JSON을 내부에서 만든다.

| 요청 필드 | 값/용도 |
| --- | --- |
| host.name | Agent certname과 같은 고유 FQDN |
| organization_id / location_id | 실제 Foreman 조직·위치 ID |
| hostgroup_id | aws/gcp/kc Host Group ID. csp 파라미터는 그룹에서 상속 |
| puppet_proxy_id / puppet_ca_proxy_id | Puppet / Puppet CA Smart Proxy ID |
| puppet_attributes.environment_id | dev는 development, prd는 production의 ID |
| puppet_attributes.puppetclass_ids | 단일 role::base/unmanaged/devops/data_infra Class ID 배열 |
| host_parameters_attributes | deploy_env, Boolean puppet_managed, 선택적 team/dr_site |
| managed / build / overwrite | 함수에서 모두 false로 고정 |

예시의 ID 1은 실제 예약 값이 아니다. 관리자가 ID·환경·Role·Proxy 연결 관계를 확인한다.
정책상 deploy_env는 dev/prd, dr_site는 primary/secondary 또는 미설정이며 role::unmanaged는 puppet_managed=false다.
ID·환경·Role의 연결 관계와 분류 정책은 호출자가 확인한다. 함수는 managed/build/overwrite를 false로 고정하고 JSON 타입과 문자열 이스케이프를 처리한다.
team/dr_site를 생략하면 상위 값이 상속될 수 있다. 명시적 null로 상속을 차단하지 않는다.

## 반환과 범위

HTTP 2xx면 Shell은 0, Go는 nil을 반환한다. 그 외 상태·통신 실패는 실패로 반환한다.
HTTPS 인증서/호스트명을 검증하고 리다이렉트를 따르지 않는다. 요청은 60초 제한이며 자동으로 재시도하지 않는다.
기존 호스트 조회/수정·최종 ENC 검증·인증서 승인·첫 Puppet 실행은 하지 않는다.
응답이 유실되면 이미 생성됐을 수 있으므로 관리 측에서 확인한다. API 성공은 전체 Agent 등록 성공과 다르다.
실제 Foreman API/RBAC·ENC 검증은 개발 서버에서 진행한다. Cloud IAM 신원을 중앙에서 검증하는 기능은 공통 서비스 TODO다.

## 테스트

```sh
bash tests/registration_test.sh
```

Go·Bash·curl·jq를 갖춘 개발 머신에서 두 구현을 같은 HTTPS 서버로 검증한다.
입력 인자로 JSON 생성·숫자 ID/Boolean/이스케이프/선택 항목 생략, POST 한 번, 성공/중복/권한/서버 오류, HTTP·리다이렉트·신뢰하지 않는 CA 거부,
PAT의 argv·환경·출력 비노출과 Shell 인증 설정 주입 거부를 확인한다.
