# user-data Foreman 등록

호출자가 접속 변수와 요청 JSON을 준비하고 함수를 호출한다.
함수는 POST /api/hosts를 한 번 보내고 성공/실패만 반환한다.

- [Shell 함수](../bootstrap/user-data/register.sh): 접속 변수 + PAYLOAD → curl
- [Go 함수](../bootstrap/user-data/go/register.go): Config + Payload → net/http
- [전체 Shell 예시](../bootstrap/examples/register.sh): 변수 설정·PAT 조회·jq로 PAYLOAD 구성·함수 호출

## Shell

Bash에서 함수 파일을 source한 뒤 다음 변수를 지정한다. source만으로 요청이 전송되지는 않는다.
`token`은 호출자가 비밀 저장소에서 읽은 PAT, `payload`는 호출자가 만든 API 요청 JSON이다.

```bash
set +x
set +a
source /opt/foreman-puppet/bootstrap/user-data/register.sh
FOREMAN_URL="https://foreman.dev.example.internal"
FOREMAN_CA_CERT="/etc/company-pki/ca.pem"
FOREMAN_USERNAME="bootstrap_dev"
FOREMAN_PAT="$token"
PAYLOAD="$payload"
foreman_register || exit 1
unset FOREMAN_PAT
```

함수에는 Bash·curl만 필요하다. 전체 예시에서 jq는 요청 JSON을 만들고, AWS CLI는 SSM에서 PAT를 가져오는 데 사용한다.
PAT 원문을 코드/user-data에 쓰거나 export하지 않는다. 함수는 PAT를 curl의 stdin으로 전달하고 응답 본문은 출력하지 않는다.

## Go

기존 Go 초기화 프로그램에 패키지를 포함하고 변수를 전달한다. Payload는 호출자가 json.Marshal 등으로 만든 JSON 바이트다.

```go
cfg := registration.Config{
    URL: "https://foreman.dev.example.internal",
    CACert: "/etc/company-pki/ca.pem",
    Username: "bootstrap_dev", Token: token,
    Payload: payload,
}
if err := registration.RegisterForeman(ctx, cfg); err != nil {
    return err
}
```

Go 표준 라이브러리만 사용하며 별도 CLI·Bash·Ruby를 호출하지 않는다.

## PAYLOAD에 넣을 값

함수가 업무 필드를 검증하거나 JSON을 만들지 않는다. 호출자가 다음 값을 준비한다.
전체 JSON 구성 코드는 [Shell 예시](../bootstrap/examples/register.sh)에 있다.

| 요청 필드 | 값/용도 |
| --- | --- |
| host.name | Agent certname과 같은 고유 FQDN |
| organization_id / location_id | 실제 Foreman 조직·위치 ID |
| hostgroup_id | aws/gcp/kc Host Group ID. csp 파라미터는 그룹에서 상속 |
| puppet_proxy_id / puppet_ca_proxy_id | Puppet / Puppet CA Smart Proxy ID |
| puppet_attributes.environment_id | dev는 development, prd는 production의 ID |
| puppet_attributes.puppetclass_ids | 단일 role::base/unmanaged/devops/data_infra Class ID 배열 |
| host_parameters_attributes | deploy_env, Boolean puppet_managed, 선택적 team/dr_site |
| managed / build / overwrite | 기존 인스턴스 신규 등록 예시에서는 모두 false |

예시의 ID 1은 실제 예약 값이 아니다. 관리자가 ID·환경·Role·Proxy 연결 관계를 확인한다.
정책상 deploy_env는 dev/prd, dr_site는 primary/secondary 또는 미설정이며 role::unmanaged는 puppet_managed=false다.
함수 안에서 필드별 검증을 하지 않으므로 JSON 문법·정책·overwrite=false는 호출자가 책임진다.
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

Go·Bash·curl을 갖춘 개발 머신에서 두 구현을 같은 HTTPS 서버로 검증한다.
요청 JSON 그대로 전달, POST 한 번, 성공/중복/권한/서버 오류, HTTP·리다이렉트·신뢰하지 않는 CA 거부,
PAT의 argv·환경·출력 비노출과 Shell 인증 설정 주입 거부를 확인한다.
