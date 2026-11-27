# NLB · Target Group 설정

개발·운영에 각각 internal NLB를 생성한다. 아래는 AWS 콘솔/구현에 사용할 계획이며 AWS 리소스 생성 코드는 아니다.
현재 값은 [계획 YAML](../server/dev.example.yaml)에 기록한다. 1단계에는 모든 TG에 Server1만 등록하고,
RDS 전환 후 3단계에 Server2를 추가한다. CA는 단일 활성 서버를 유지한다.

## Listener와 Target Group

| Listener | Target Group 이름 예시 | TG 프로토콜·포트 | TLS 인증서 | 초기 Health check |
| --- | --- | --- | --- | --- |
| TLS 443 | foreman-web | TCP 80 | NLB에 ACM, backend HTTP | TCP traffic-port (80) |
| TCP 7443 | foreman-service | TCP 443 | NLB 없음, 서버의 내부 서비스 인증서 | TCP traffic-port (443) |
| TCP 8140 | openvox-agent | TCP 8140 | NLB 없음, Agent·서버의 OpenVox CA 인증서 | TCP traffic-port (8140) |

세 TG의 target type은 instance, 대상 포트는 표와 같다. Listener의 기본 동작은 해당 TG로 forward한다.
TCP Listener도 실제 애플리케이션 통신은 TLS/mTLS다. NLB는 이 TLS를 종료하지 않는다.
웹 TLS Listener에는 ACM ARN과 조직이 승인한 TLS 1.2 이상 보안 정책을 지정한다.
NLB 443은 승인된 웹/API 클라이언트에 개방한다는 의미이며 인터넷 공개 NLB를 의미하지 않는다.

- IP 유형: 우선 IPv4. 향후 IPv6 지원 시 SG·DNS·접근 경로를 함께 변경한다.
- SG는 NLB 생성 시 연결한다. SG 없이 만든 NLB에는 나중에 SG를 추가할 수 없다.
- TG의 `preserve_client_ip.enabled=false`, `proxy_protocol_v2.enabled=false`를 명시한다.
  특히 관리 서버가 서비스 NLB를 호출한 뒤 자기 자신으로 돌아오는 hairpin 경로를 검증한다.
  backend 로그에는 원래 클라이언트 IP가 보존되지 않으므로 이를 감사 설계에 반영한다.
- 복수 AZ의 서브넷을 선택한다. 현재 계획은 cross-zone을 활성화해 단일 대상 및 AZ별 대상 불균형을 처리한다.
  Server2 추가 시 AZ별 배치·잔여 용량·교차 AZ 비용을 검토한다.
- Health interval 30초, healthy/unhealthy threshold 각 3회로 시작한다. 실제 제외 시점은 단순히 90초로 보장되지 않는다.
- 실제 앱/DB·Compiler 준비 상태는 TCP 검사만으로 알 수 없다. 운영 HA 전 readiness 검증이 필요하며,
  모든 대상 unhealthy 시 NLB fail-open 가능성도 반영한다.

## 보안 그룹

| 위치 | inbound 허용 |
| --- | --- |
| NLB SG | 443: 승인된 사용자·user-data 실행 노드, 7443: 관리 서버, 8140: 관리 대상 노드 네트워크 |
| EC2 SG | NLB SG를 소스로 80·443·8140 허용 |
| 각 Smart Proxy EC2 SG | Foreman 관리 서버에서 해당 서버 8443 허용 |
| 활성 CA EC2 SG | 승인된 노드·관리 서버에서 CA 직접 연결용 8140 허용 |

NLB SG outbound도 TG/health 대상 80·443·8140을 허용한다. EC2 SG는 NLB SG를 참조해 직접 우회 접근을 제한한다.
CA 8140의 직접 허용은 CA 역할을 맡은 서버에만 둔다. 로컬 DB 5432는 NLB로 노출하지 않는다.
각 SG 참조 가능 여부와 AWS/GCP/KC 간 라우팅·CIDR·방화벽은 실제 네트워크에서 확인한다.
22는 Puppet 적용용으로 필요하지 않으며 SSH 관리가 필요한 경우 별도 승인 경로로 제한한다.

## Foreman HTTP backend 적용 전 필수 확인

웹 경로는 `HTTPS → NLB → HTTP:80`으로 바뀐다. HTTPS 443 vhost는 내부 7443 연동에 계속 필요하므로
`foreman.ssl=false`로 끄지 않는다. installer 템플릿은 HTTP 80과 HTTPS 443을 유지한다.
외부 URL은 계속 `https://foreman_fqdn`, 내부 서비스 URL은 `https://foreman_service_fqdn:7443`이다.

**현재 설치 코드는 HTTP offload의 프록시 헤더 구성을 자동 적용하지 않는다.** 실제 Foreman/installer 버전에서
다음 설정을 검증·지속 관리하기 전 웹 TG를 80으로 전환하지 않는다. NLB 설정만 바꾸면 리다이렉트 루프가 날 수 있다.

1. NLB는 L4라 `X-Forwarded-Proto`를 추가하지 않는다. NLB 전용 HTTP vhost가 애플리케이션으로 전달할 때
   `X-Forwarded-Proto: https`를 강제로 설정해야 한다. 클라이언트가 준 값을 그대로 신뢰하지 않는다.
2. HTTP vhost에서 클라이언트가 보낸 `SSL-CLIENT-*` 및 외부 인증 신원 헤더를 제거/초기화한다.
   PAT·세션 인증은 Foreman이 검증하며 HTTP 요청을 인증서 인증으로 취급하지 않는다.
3. 기본 vhost에는 HTTP의 proto 헤더 설정이 있으므로 별도 파일에 헤더 한 줄을 추가하는 것만으로 충분하다고 가정하지 않는다.
   설치된 puppet-foreman의 `foreman::config::apache::http_vhost_options` 등 지원되는 설정 경로와 병합 동작을 확인한다.
   Foreman installer 재실행 후에도 유지돼야 한다.
4. NLB를 통해 로그인·리다이렉트·Secure cookie·PAT 등록 API를 확인한다. 내부 7443의 클라이언트 인증서 인증도 회귀 확인한다.
   NLB를 우회한 HTTP 80 접속은 SG에서 차단됐는지 확인한다.

backend HTTP 구간은 평문이다. 해당 구간까지 암호화가 필요해지면 웹 TG를 TLS 443으로 되돌리는 별도 결정이 필요하다.

## NLB로 분산하지 않는 경로

- `ca_fqdn:8140 → 활성 CA Server1`: 발급·갱신. Server2는 같은 CA를 신뢰하는 고유 인증서를 사용한다.
- `host_fqdn:8443 → 해당 Smart Proxy`: Foreman이 지정한 Proxy를 직접 호출한다.
- CA의 서명용 개인키는 활성 CA와 안전한 백업에만 두며 NLB나 각 Compiler에 복제하지 않는다.

인증서·장애 예시는 [ACM과 내부 TLS](ACM_AND_BACKEND_TLS.md), 복구 절차는 [장애 대응](FAILURE_RUNBOOK.md)을 참조한다.

근거: [AWS NLB Listener](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html),
[NLB SG](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html),
[TG 속성](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/edit-target-group-attributes.html).
