# user-data 최초 Foreman 등록

등록 실행기는 `bootstrap/agent/register.sh`, 입력 예시는
[`registration.json`](../bootstrap/examples/registration.json)이다. 기본 실행은 네트워크와 비밀 조회가 없는 계획 출력이며,
`--apply`에서만 HTTPS API를 호출한다. Bash(curl+jq)와 Go(net/http) 두 구현이 각각 API를 직접 호출한다. 등록 과정에서 Ruby/Python을 실행하지 않는다.
실제 Foreman 5.0 + foreman_puppet 환경의 API/RBAC·ENC 통합 검증은 아직 수행하지 않았다.

## 파일과 입력을 준비하는 순서

```text
bootstrap/
├── agent/register.sh                  # Bash CLI: 기본 plan, --apply만 등록
├── lib/registration.jq                # Bash 입력/ENC 검증·요청 JSON 구성
├── user-data/register.bash            # source해서 부르는 직접 API 등록 함수
├── user-data/go/                      # 독립 Go API 클라이언트
│   ├── register.go                    # RegisterForeman(ctx, config, apply)
│   ├── register_test.go               # Go/Bash 공통 HTTPS 시나리오 검증
│   └── cmd/foreman-register/main.go    # Go CLI 진입점
├── examples/registration.json         # 복사 후 인스턴스별로 수정할 입력 예시
├── local/registration.json            # 운영자가 만드는 실제 입력, Git 제외
└── user-data/registration.yaml        # 사전 배치된 코드·입력을 실행하는 cloud-init 예시
```

1. 관리 서버 설치 후 조직·위치·CSP Host Group·Puppet Environment·Class·Smart Proxy를 준비한다.
   Host Group 이름은 `aws/gcp/kc`, 그룹 파라미터 `csp`도 같은 값으로 설정한다.
   그룹이나 상위 그룹에서 Role을 상속하지 않도록 하고, 생성할 호스트에는 단일 Role을 배정한다.
2. 전용 계정과 만료일 있는 PAT를 관리 측에서 발급한다. 조직/위치와 생성 가능한 범위를 제한하고,
   호스트 조회·ENC 조회·참조 조회·신규 호스트/파라미터/Class 배정에 필요한 권한을 검증한다.
   기존 호스트 수정·삭제 권한은 부여하지 않는 것을 목표로 한다. 스크립트는 수정·삭제 API를 호출하지 않는다.
3. AWS SSM SecureString에 PAT를 저장한다. 노드 IAM Role에는 해당 파라미터 조회와 필요한 KMS 복호화만 허용한다.
   AWS CLI는 이미지나 별도 초기화 단계에서 설치해야 하며 실행기가 설치하지 않는다.
4. 검토한 저장소 커밋의 코드를 노드 `/opt/foreman-puppet`에 배치하고 OpenVox Agent를 설치한다.
   등록만 실행할 때는 Agent/Ruby가 없어도 된다. 코드 다운로드·Agent 설치 방법은 기존 [bootstrap 실행 순서](../bootstrap/README.md)를 따른다.
5. **이 시점에 입력 파일을 만든다.** 아래처럼 예시를 복사하고, 실제 값으로 수정한 다음 plan을 실행한다.

```sh
cd /opt/foreman-puppet
install -d -m 0700 /etc/foreman-bootstrap
install -m 0600 bootstrap/examples/registration.json /etc/foreman-bootstrap/registration.json
# 편집기 또는 IaC/cloud-init write_files로 실제 입력을 작성한다.
vi /etc/foreman-bootstrap/registration.json
bash bootstrap/agent/register.sh --config /etc/foreman-bootstrap/registration.json
# 계획을 확인한 뒤 최초 등록 실행
sudo bash bootstrap/agent/register.sh --config /etc/foreman-bootstrap/registration.json --apply
```

plan은 입력 형식만 확인한다. 인증서 파일·ID 존재·권한·네트워크의 유효성을 확인하지 않는다.
[cloud-init 예시](../bootstrap/user-data/registration.yaml)는 이미 준비된 파일을 실행한다.
해당 예시 하나로 Agent와 입력 파일이 자동 설치되지는 않는다.

## 입력 항목

| 입력 | 작성 기준 |
| --- | --- |
| `foreman.url` | 사내 인증서로 검증할 Foreman HTTPS origin. 경로·사용자명·토큰을 URL에 넣지 않음 |
| `foreman.ca_cert` | 노드에 사전 배치한 사내 CA PEM 파일 절대 경로 |
| `foreman.username` | PAT를 발급받은 등록 전용 Foreman 계정 |
| `auth.source/region/reference` | `aws_ssm`, 리전, SecureString 이름 또는 ARN. PAT 원문 아님 |
| `host.name` | Agent `certname`과 같은 고유 FQDN. 예시의 EXAMPLE은 실제 값으로 반드시 교체 |
| `host.bootstrap_identity` | IaC가 전달하는 안정적인 인스턴스 신원. 예: `aws/계정ID/리전/인스턴스ID` |
| `host.csp` | `aws/gcp/kc`. Host Group 이름과 일치해야 함 |
| `organization_id/location_id` | 실제 Foreman 조직·위치 ID. 예시의 1은 예약된 값이 아님 |
| `hostgroup_id` | 해당 CSP 그룹 ID. 실행 전에 ID의 이름을 조회해 대조 |
| `environment_id/environment` | Puppet Environment ID와 `development/production` 이름. ID/이름 대조 |
| `role_id/role` | Puppet Class ID와 `role::base/unmanaged/devops/data_infra` 중 하나. ID/이름 대조 |
| `puppet_proxy_id/puppet_ca_proxy_id` | 설치된 Smart Proxy의 Puppet/Puppet CA 기능에 대응하는 ID |
| `parameters.deploy_env` | `dev/prd`. Puppet Environment와 대응. sandbox는 TODO |
| `parameters.team` | 팀 문자열 또는 `null`(미설정) |
| `parameters.dr_site` | `primary/secondary` 또는 `null` |
| `parameters.puppet_managed` | JSON Boolean. 미관리 Role은 `false` 필수 |

`foreman-host.json`은 기존 설명용 논리 입력이며, 실행기는 `registration.json` 형식을 받는다.
실제 ID는 Foreman UI/API에서 확인한다. 입력은 사전에 조직·위치·Proxy 간 연결 관계까지 확인해야 한다.
실행기는 고정 ID를 다른 서버에서 그대로 재사용해도 된다고 보장하지 않는다.

GCP/KC처럼 비밀 조회 경로를 아직 정하지 않은 환경에는 `auth`를
`{"source":"file","path":"/run/foreman-bootstrap/pat"}`로 지정할 수 있다.
이 파일은 별도 보안 경로에서 배치한 root 소유 일반 파일, 권한 0600이어야 하며 symlink는 거부한다.
실행기가 파일을 생성하거나 삭제하지 않는다. 호출자가 성공·실패 모두 정리하고 PAT 폐기는 관리 측에서 수행한다.

## 생성·재실행과 실패 처리

- 신규 생성은 `POST /api/hosts` 한 번이다. `managed=false`는 OS 프로비저닝을 하지 않는다는 뜻이며,
  시스템 설정 관리 여부인 `puppet_managed`와 다르다. `overwrite=false`를 명시한다.
- `puppet_attributes`로 환경과 단일 Role Class를 지정한다. `puppet_managed`는 Boolean 타입으로 전달한다.
  `bootstrap_identity`는 호스트 파라미터에 저장하고 `csp`는 Host Group에서 상속한다.
- `team/dr_site=null`은 API에 빈 문자열을 넣지 않고 해당 호스트 파라미터를 생략한다.
  상위 그룹·조직·전역에서 값이 상속되면 null과 다르므로 생성 후 ENC 검증이 실패한다.
  미설정을 원하면 상위 기본값도 없도록 준비한다. 상속을 null로 강제 차단하는 기능은 구현하지 않았다.
- 동일 이름이 있으면 조직·위치·클라우드 신원·CSP와 현재 ENC 정책을 확인하고 **조회만** 한다.
  Foreman에서 변경한 Role·환경·팀 등은 user-data의 과거 값으로 복구하지 않는다.
  이 단계는 입력 형식을 확인하며, 이미 존재하는 호스트에 대해서는 초기 참조 ID를 재배정하지 않는다.
- 이름이 같아도 신원이 다르면 실패한다. 새 인스턴스에는 새 certname을 부여하고,
  삭제 노드의 Foreman 호스트·인증서 정리는 별도로 수행한다.
- POST 응답이 실패하면 이름으로 다시 조회한다. 같은 신원이 확인될 때만 보존 상태로 마친다.
  자동으로 POST를 재시도하지 않는다. GET 실패·권한 거부·TLS 실패는 비정상 종료한다.
- 생성 후 ENC 검증 실패 시 이미 호스트가 남아 있을 수 있다. 오류 원인을 관리 측에서 확인하고 수정한다.
  실행기는 생성한 호스트도 삭제하거나 정책을 덮어쓰지 않는다. 재실행은 현재 중앙 정책을 검증하는 동작이다.

PAT는 실행 프로세스 메모리에서 HTTP Basic 인증에 사용하며, API 응답 본문이나 토큰을 로그에 출력하지 않는다.
Bash는 curl 인증 설정을 표준 입력 파이프로 전달해 PAT를 argv·환경변수·임시 파일에 넣지 않는다.
Go는 net/http 요청 헤더를 메모리에서 구성하며 Bash·curl·Ruby를 호출하지 않는다.
두 구현의 aws_ssm 공급 방식은 AWS CLI를 사용한다. 별도의 Python 버전 관리를 피하려면 AWS CLI v2 배포본을 사용한다.
HTTPS 호스트명·CA 검증을 끄지 않으며 리다이렉트를 따라가지 않는다. 입력 파일과 신원은 IaC가 제공하는
값이므로 AWS가 서명한 신원을 중앙에서 검증한 것으로 간주하면 안 된다. PAT와 RBAC가 현재의 보안 경계다.
인스턴스 신원 검증을 포함한 공통 등록 서비스는 향후 API Gateway+Lambda TODO다.

## 다음 확인

소스 테스트 이후 실제 개발 Foreman에서 전용 계정으로 신규 생성·ENC Boolean/null·재등록·권한 거부를 확인한다.
그다음 Agent 설정의 certname 일치 → 내장 CA CSR/수동 승인 → 첫 Catalog 적용과 Report를 검증한다.
이 실행기의 성공은 **Foreman 호스트/ENC 등록 확인**이며 인증서 발급이나 첫 Puppet 적용의 성공을 뜻하지 않는다.
Agent 서비스를 시작하거나 인증서를 승인하는 동작은 포함하지 않는다.

```sh
bash tests/registration_test.sh
```

API 형식 근거: [Foreman 5.0 hosts/create](https://apidocs.theforeman.org/foreman/5.0/apidoc/v2/hosts/create.html),
[Foreman ENC API](https://github.com/theforeman/foreman/blob/5.0-stable/app/controllers/api/v2/hosts_controller.rb),
[foreman_puppet 소스](https://github.com/theforeman/foreman_puppet/tree/12c6ed2aff45bd15a9cf1515001110a92a2f7768).

## 기존 user-data에 함수로 결합하기

Bash는 [`register.bash`](../bootstrap/user-data/register.bash)를 source한다. source만으로 실행되지 않는다.
실제 입력 파일·사내 CA·curl·jq·coreutils와 필요 시 AWS CLI를 준비한 뒤 함수를 호출한다. 세 번째 인자를 생략하면 plan이다.

```bash
source /opt/foreman-puppet/bootstrap/user-data/register.bash
foreman_register /opt/foreman-puppet /etc/foreman-bootstrap/registration.json plan
# 실제 최초 등록 단계
foreman_register /opt/foreman-puppet /etc/foreman-bootstrap/registration.json apply
```

이 함수 안에서 직접 API를 호출한다. `register.sh`는 같은 함수를 부르는 CLI이며 선택적으로 사용한다.
Agent 설치·입력 작성·CSR 승인은 별도 단계다. 단독 CLI의 --apply는 기존대로 root로 실행한다.
재사용 API 함수 자체에는 OS 변경이 없으므로 root를 강제하지 않으며, API 계정/PAT와 IAM 권한으로 인증한다.
file 공급 방식은 어느 구현에서도 root 소유 0600 파일만 허용한다. 일반적인 cloud-init은 root로 실행된다.
Bash file 공급은 GNU stat/dd의 nofollow/nonblock 기능을 사용하므로 비밀 파일은 root 전용 디렉터리에 배치한다.

## Go 함수 또는 실행 파일 사용

Go는 같은 입력 JSON을 받지만 Bash나 jq가 필요하지 않다. 표준 라이브러리만 사용하고 모듈의 최소 Go 버전은 1.22다.
실제 빌드는 보안 업데이트가 적용된 지원 Go 버전으로 수행한다. 대상 Linux 노드에는 빌드한 바이너리만 배포한다.

```sh
cd bootstrap/user-data/go
# 개발/빌드 머신에서 실행. 산출물은 Git 제외인 bootstrap/local/ 아래에 둔다.
mkdir -p ../../local
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -o ../../local/foreman-register-amd64 ./cmd/foreman-register
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -o ../../local/foreman-register-arm64 ./cmd/foreman-register
```

노드 아키텍처에 맞는 실행 파일을 배치한 뒤 실행한다. Go CLI도 기본은 plan이다.

```sh
/opt/foreman-bootstrap/foreman-register --config /etc/foreman-bootstrap/registration.json
sudo /opt/foreman-bootstrap/foreman-register --config /etc/foreman-bootstrap/registration.json --apply
```

기존 Go 초기화 프로그램에는 모듈을 의존성으로 추가하거나 패키지를 내부 코드로 편입해서 아래처럼 호출한다.
이 함수는 외부 Bash 스크립트를 부르는 어댑터가 아니라 직접 Foreman API를 호출한다.

```go
import (
    "context"
    "encoding/json"
    "os"
    "time"
    registration "github.com/heyoon2j/y2-devops-lab/foreman-puppet/bootstrap/user-data/go"
)

// 기존 Go 초기화 프로그램에서 호출할 함수 예시.
func registerNode() error {
f, err := os.Open("/etc/foreman-bootstrap/registration.json")
if err != nil { return err }
cfg, err := registration.LoadConfig(f)
f.Close()
if err != nil { return err }
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
defer cancel()
result, err := registration.RegisterForeman(ctx, cfg, true)
if err != nil { return err }
return json.NewEncoder(os.Stdout).Encode(result)
}
```

Bash와 Go 중 하나만 선택해 실행한다. 두 구현은 같은 JSON·API 요청·중앙 정책 보존 기준을 사용하며
테스트에서 동일한 HTTPS 서버 시나리오를 통과해야 한다. Go 테스트가 두 구현을 함께 검증하므로
테스트 머신에는 Go·Bash·curl·jq·GNU coreutils가 필요하다. 실제 Foreman 연동 검증과는 별개다.
