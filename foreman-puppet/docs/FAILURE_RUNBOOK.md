# 장애 대응

상태: 2026-11-22 합의한 배치를 기준으로 작성한 운영 절차 초안. 실제 장애 전환·복원 시험 전이다.
개발/운영별 실측 정보와 RTO/RPO를 채우고 리허설한 뒤 실행 절차로 확정한다.
문서 작성 과정에서 서버·DNS·CA·S3는 변경하지 않았다.

## 단계별 장애 판별과 공통 대응

최신 구축 순서는 개발·운영 각각 ① LB+Server1+로컬 DB ② 로컬 DB→RDS ③ Server2 추가/CA 포함
이중화다. [단계별 계획](PHASED_ROLLOUT.md)을 따른다. 개발 장애 복구에 운영 DB/CA를 섞지 않는다.

| 장애 | 1단계/2단계 | 3단계 | 우선 대응 |
| --- | --- | --- | --- |
| Server1 중단 | 유일한 백엔드 중단. 1단계는 DB도 영향 | 정상 Server2로 일반 요청 처리, CA는 별도 복구 | NLB TG·EC2·디스크·서비스·DB 확인, CA fencing |
| NLB/네트워크/DNS | 대상이 정상이어도 접속 불가 | 두 서버여도 경로 장애 영향 | listener/TG·SG·routing·DNS·TLS와 동일 대상 hairpin 구분 |
| 로컬 DB 장애 | Foreman 등록/ENC/Report 중단 | 로컬 DB 사용 안 함 | 디스크·서비스·DB 로그 확인, 일관된 백업과 비밀값으로 복구 |
| RDS 장애 | 2단계 Foreman 기능 영향 | 같은 환경의 두 Foreman에 영향 | RDS 상태/이벤트·접속/TLS·Multi-AZ 전환 확인 |
| Compiler/코드 오류 | 최신 Catalog 생성 실패 | 공통 코드 오류면 두 서버 모두 실패 | 오류 Report·서버 로그·commit 확인, 검증된 이전 코드로 복귀 |
| 인증서/CA/CRL 오류 | 최초 발급과 기존 통신 영향을 분리 | 유효한 신뢰/CRL 없으면 정상 Server2도 실패 | 만료·DNS SAN·체인·폐기 상태 구분, 아래 CA 상세 절차 |
| API 등록 인증 실패 | user-data 등록 실패 | 동일 | PAT 만료/폐기·계정 권한·비밀 조회·CA 신뢰 확인, 토큰 출력 금지 |

1. 영향 환경·시각·호스트와 변경 이력을 기록하고 배포·신규 등록의 추가 변경을 잠시 멈춘다.
2. DNS→NLB/TG→서버 서비스→DB/인증→코드 순으로 원인을 나눈다. 무작정 재설치/CA 초기화하지 않는다.
3. DB 복구는 RDS에 새 쓰기 전/후의 경계를 지킨다. 옛 로컬 DB로 단순 복귀하지 않는다.
4. 코드 복귀는 두 Compiler에 같은 검증 commit을 사용한다. Puppet 코드 rollback이 이미 적용한
   노드 설정을 자동 원복하는 것은 아니므로 필요 시 복구 Catalog를 별도로 적용한다.
5. 복구 후 웹/API·ENC·대표 Agent의 첫/두 번째 적용·최신 Facts/Report·등록·모니터링을 검증한다.
6. 장애 원인·상태 손실·실제 복구 시간을 기록하고 백업과 재발 방지 항목을 갱신한다.

DB 이전/복구 경계는 [단계별 계획](PHASED_ROLLOUT.md), LB 세부 조건은 [LB 설계](LB_AND_SCALING.md)를
따른다. 실제 DB 복원·AWS 조작 명령은 환경 정보와 복원 리허설을 준비한 뒤 작성한다.

## CA 장애 상세 절차

이하 CA 상태 승계는 전체 장애 대응 중 CA 영역의 절차다.

## 적용 범위와 현재 구현의 차이

이 절차는 **OpenVox 내장 CA를 서버 1에서만 실행하고, 장애 시 같은 CA 상태를 서버 2로 수동 승계**하는
구성을 대상으로 한다. Foreman 웹/API는 사내 인증서를 사용하고 Agent 통신용 내장 CA와 구분한다.
개발/운영 CA는 각각 독립적이며 개발 CA 상태를 운영에 복원하지 않는다.

현재 bootstrap은 Server1의 명시적 ca-init와 내장 CA 설정을 지원한다. 실제 설치 검증과
백업·복구 자동화 및 Server2/Standby 설정은 아직 구현/검증 전이다. 초기화 단계를 장애 복구에 사용하지 않는다.
전환 전에 설정·인증서·CA 신뢰·Smart Proxy Puppet CA 연동을 별도 검증한다.
이 문서는 자동 CA 이중화나 무중단 발급을 보장하지 않는다.

## 배치와 영향

| 경로 | 평상시 | 서버 1 장애 시 |
| --- | --- | --- |
| foreman-dev.example.internal:443 | NLB → Foreman 1/2 | 정상 서버 2 사용. 공용 DB 등 의존성 정상 전제 |
| puppet-dev.example.internal:8140 | NLB → Compiler 1/2 | 기존 Agent는 서버 2로 Catalog/Facts/Report 처리 |
| puppet-ca-dev.example.internal:8140 | 사설 DNS → CA 서버 1 | CA 승계 검증 후 DNS를 서버 2로 전환 |

위 도메인은 예시다. 운영은 별도의 운영용 도메인을 사용한다.
CA는 Compiler NLB의 일반 풀에 넣지 않는다. DNS만 바꿔서는 CA 상태·서비스·인증서가 복구되지 않는다.
CA 중단 중 신규 인증서 발급·승인·갱신·폐기는 중단된다. 유효한 인증서로 기존 Catalog 통신을
지속하려면 Foreman/DB·코드·Server TLS·CRL 등의 의존성이 정상이어야 한다.
CA 전용 주소만 바꾸며 Agent의 server/ca_server 설정은 유지한다.

개발·운영 1단계는 각각 LB + Server1 + 로컬 DB다. LB가 있어도 정상 백엔드가 없으면 서비스할 수 없다. 이 서버가 중단되면 전체 기능이 중단되므로
대체 서버에 DB·Foreman 설정/비밀값·코드·인증 자료까지 복구해야 한다. CA만 복구해서 완료로 보지 않는다.
이하 서버 2 승계는 공용 RDS와 검증된 Compiler 2가 있는 3단계(2대 구성)의 절차다.

## 장애 전에 준비할 정보

| 항목 | 환경별 기록할 값 |
| --- | --- |
| 장애 대응 담당·변경 기록 위치 | 미정 |
| 서버 1/2의 인스턴스 ID·AZ·관리 주소 | 미정 |
| Foreman/Puppet/CA 도메인·DNS zone·기존 레코드·TTL | 미정 |
| CA 서버 2 전환 시 도메인을 수용하는 서버 인증서 SAN | 실측 필요 |
| OpenVox Server/Agent 전체 패키지 revision·설정 버전 | 실측 필요 |
| cadir / ssldir / 서비스 사용자·그룹·권한 | 설치 후 확인 |
| 백업 저장소·객체 버전·KMS 키·복구 IAM 권한 | 미정 |
| 마지막 정상 백업 시각·무결성 기록·발급/폐기 변경 기록 | 미정 |
| 허용 복구 시간(RTO)·상태 손실(RPO) | 미정. 일일 백업을 RPO=0으로 보지 않음 |
| 승인된 검증 노드·새 certname·시험 폐기 대상 | 미정 |

서버 2는 자신의 고유 certname·개인키·서버 인증서를 가진다. 같은 CA를 신뢰하고 서버 인증서에는
공통 Puppet 도메인과 승계 후 사용할 CA 도메인의 SAN이 필요하다. Foreman/Proxy의 허용 목록도 확인한다.
서버 2가 원래 Compiler로 동작할 때 CA 기능은 비활성이고, 일반 Compiler에 CA 개인키를 상시 복제하지 않는다.
복원 권한은 장애 복구 담당 경로로 제한한다.

## 백업 기준

실제 cadir 전체를 일관된 시점으로 보존한다. 기본 경로는 /etc/puppetlabs/puppetserver/ca/다.
CA 키·인증서뿐 아니라 중간/루트 CA 자료, serial·inventory, signed/·requests/, CRL 및
infra_* 등 실제 존재하는 상태를 모두 포함한다. 파일 목록을 임의 축소하지 않는다.

- 일일 백업과 발급·갱신·폐기 등 상태 변경 후 백업을 계획한다. 자동 갱신도 상태 변경이다.
- 백업 중 상태 변경을 배제하거나 일관성을 확인한다. 단순 실행 중 디렉터리 복사만으로 성공 판정하지 않는다.
- CA 설정·패키지 버전·서버별 SSL 자료도 복구용으로 별도 보존하되 서버 간 덮어쓰기 대상과 구분한다.
- S3를 사용하면 전용 비공개 버킷, Public Access Block, SSE-KMS, 버전 관리와 최소 IAM 권한을 적용한다.
  읽기/복호화와 쓰기/삭제 권한을 분리하고 KMS 키 접근도 제한한다. 실제 S3 구성은 후속 작업이다.
- 백업 객체의 시각·버전·해시와 원래 소유권/권한을 기록하고 다른 호스트에서 복구 시험한다.
- CA 상태는 Foreman RDS에 들어 있지 않다. DB 백업으로 CA 상태가 복구되지 않는다.

## 1. 장애 판별과 이중 실행 차단

1. CA 경로 문제인지 서버 전체·네트워크·DNS·TLS·시간 문제인지 구분한다. Foreman/Puppet NLB의
   정상 서버 2 동작도 별도로 확인한다. 신규 발급과 갱신 작업을 일시 중지한다.
2. 장애 시각·기존 CA 담당·DNS 값·마지막 상태 변경·마지막 백업을 기록한다.
3. **서버 1의 CA가 재실행되지 못하도록 먼저 차단한다(fencing).** 인스턴스 정지/격리, 자동 복구 및
   CA 자동 활성화 차단을 확인한다. 단순 ping 실패나 DNS 변경은 차단의 증거가 아니다.
4. 서버 1을 확실히 차단하지 못했다면 서버 2의 CA 발급을 활성화하지 않는다.
   같은 CA의 상태를 두 곳에서 동시에 변경하면 일련번호·폐기 기록이 갈라질 수 있다.

확인용 예시(실제 도메인·경로로 대체):

```sh
date -u
dig +noall +answer puppet-ca-dev.example.internal
systemctl status puppetserver --no-pager
openssl x509 -in /etc/puppetlabs/puppetserver/ca/ca_crt.pem -noout -subject -issuer -dates -fingerprint -sha256
```

인증서 번들이면 위 openssl 출력은 첫 인증서만 확인한다. 체인 전체의 만료·발급 관계도 별도로 검증한다.
개인키 내용이나 인증 토큰을 장애 기록에 출력하지 않는다.

## 2. 복구 자료 선정과 상태 공백 확인

1. 같은 환경·같은 CA의 최신 일관된 백업을 선택하고 해시·복호화·무결성을 확인한다.
2. 서버 1의 최신 디스크를 안전하게 확보할 수 있으면 변경을 멈춘 상태의 최신 CA 자료와 대조한다.
3. CA 인증서 지문을 사전에 기록한 값과 비교하고 인증서/CA 키의 일치 및 전체 체인을 검증한다.
4. **백업 이후 발급·갱신·폐기 내역이 누락되었는지 확인한다.** 오래된 serial로 새 발급을 시작하면
   일련번호 재사용이 생길 수 있고, 백업 이후 폐기한 인증서가 다시 허용될 수 있다.
5. 공백이 있으면 최신 상태 확보 또는 공식 복구 절차에 따른 발급/폐기 이력 대조·재등록 계획을
   먼저 확정한다. serial을 추정해 수정하거나 signed/만 일부 복사해 최신 상태라고 판정하지 않는다.
   이력이 확인되지 않으면 발급 재개를 보류한다. 영향 노드·실제 RPO를 기록한다.
6. CA 키 분실·유출 또는 CA 만료 문제는 단순 서버 장애 승계와 구분한다. 지문/키가 다른 새 CA를
   자동 생성해 대체하지 않고 별도 CA 복구·교체 절차로 처리한다.

**신원 보존과 최신 상태 보존은 다르다.** 같은 CA 키라도 오래된 백업만으로 모든 발급 이력이 복구되지는 않는다.
과거 백업 복구 시 일괄 ca clean을 실행하지 않는다. 일련번호 재사용과 폐기가 충돌할 수 있으므로
[공식 CA 백업 복구 절차](https://docs.openvoxproject.org/openvox-server/latest/backup_restore.html)를 따른다.

## 3. 서버 2에 CA 복원·활성화

1. 서버 2의 현재 설정·서버 인증서·개인키·CA 비활성 상태를 별도로 백업한다.
2. 복원 중 Agent/설정 자동화가 CA를 초기화하거나 이전 설정을 되돌리지 못하도록 중지한다.
3. 일관된 cadir 전체를 서버 2에 복원하고 설치 버전에 맞는 소유권·권한·설정 경로를 확인한다.
   CA 상태가 아닌 서버 1의 ssldir 전체를 서버 2에 덮어쓰지 않는다. 서버 2의 고유 신원은 유지한다.
4. 기존 CA 지문·키 일치·일련번호/발급 목록·최신 CRL·CRL 만료와 Server TLS의 CA 신뢰를 검증한다.
5. 검증한 설정 절차로 서버 2의 CA 기능을 활성화한다. **새 CA setup/키 생성은 실행하지 않는다.**
   Server1용 ca-init를 장애 복구에 사용하지 않는다. 최초 Server1용 configure도 검토 없이 재실행하지 않는다.
6. 같은 JVM의 CA 활성화에 puppetserver 재시작이 필요한 경우 계획된 중단으로 처리한다.
   서버 1이 이미 중단된 상태에서 서버 2까지 재시작하면 그동안 Catalog 통신도 중단될 수 있다.
7. DNS 전환 전에 새 서버를 직접 대상으로 CA 도메인의 SNI·SAN·신뢰 체인 및 실제 CA API 응답을
   검증한다. TCP 8140 연결 성공만으로 판정하지 않는다. 이 단계까지 일반 신규 발급은 계속 차단한다.

새 서버도 CA 인증서만 복사해 TLS 서버 인증서로 사용하는 것이 아니다. CA 인증서와 서버 인증서는 용도가 다르다.
Compiler 1/2의 CRL 배포·갱신 경로도 확인한다. CA 상태를 복원했다고 다른 Compiler의 CRL이
자동으로 최신화된다고 가정하지 않는다.

## 4. CA DNS 전환

1. CA 전용 DNS 레코드의 현재 값·TTL·변경 시각을 기록한다.
2. 복원·검증된 서버 2의 사설 주소로 puppet-ca-dev.example.internal을 변경한다.
   Foreman/Puppet NLB 도메인은 변경하지 않는다. CA 이름을 일반 Compiler 풀로 보내지 않는다.
3. 각 CSP의 대표 노드에서 권한 DNS와 실제 사용하는 resolver 결과를 확인한다.
   기존 TTL·로컬/중간 캐시 때문에 즉시 전환되지 않을 수 있다. 이전 CA 서버는 계속 차단한다.
4. Foreman의 CA Smart Proxy 연결도 검증한다. CA 담당이 바뀌었다면 호스트/Host Group의
   CA Proxy 연결 및 Proxy 측 CA endpoint가 옛 서버를 가리키지 않도록 조정한다.
   Agent의 DNS만 바꿔도 Foreman 서명 UI까지 자동 전환된다고 가정하지 않는다.
5. 모든 Agent의 ca_server가 이 논리 이름을 사용하는지 확인한다. 서버 1의 실제 호스트 이름으로
   고정한 노드는 별도 정정 대상이다.

## 5. 복구 완료 검증

| 시험 | 완료 기준 |
| --- | --- |
| 기존 대표 노드 | 기존 인증서를 바꾸지 않고 Server 2를 통해 Catalog 적용. detailed exit code 0/2와 최신 Foreman Report 확인 |
| 새 시험 노드 | 고유 certname으로 CSR 요청·정책에 따른 승인·수령·첫 Catalog/Report 성공 |
| 갱신 | 갱신을 활성화한 경우 시험 노드의 실제 인증서/만료일 변경 확인. 명령 종료 코드만으로 판정하지 않음 |
| 폐기 | 격리한 폐기 시험 노드가 새 TLS 연결에서 차단되고 Compiler CRL에 반영됨. 운영 노드를 시험 폐기하지 않음 |
| Foreman API | PAT 등록·기존 호스트 검증, 중앙 Role/파라미터 보존 확인 |
| CA 단일 실행 | 서버 2만 활성, 서버 1이 복귀해도 CA가 자동 시작되지 않음 |
| 상태 보존 | 승계 후 새 백업 완료, 누락 이력/영향 노드와 미해결 사항 기록 |

신규 등록 차단을 해제하고 장애 기록에 CA 담당·DNS·백업 객체 버전·지문·실제 중단 시간·RPO를 남긴다.
CA 발급·갱신·폐기를 감시하고 인증서/CA/CRL 만료 알림을 확인한다.

## 6. 실패 시 중단·복귀 기준

- DNS 전환 전 실패: 일반 발급을 열지 않는다. 원인을 해결하고 재검증한다. 서버 1의 fencing은 유지한다.
- DNS 전환 후 새 발급/폐기 전 실패: 상태 변경이 없음을 확인하고 최신 상태를 가진 검증된 CA로만 복귀한다.
- 서버 2에서 발급·갱신·폐기 후 실패: **옛 서버 1/백업으로 DNS만 되돌리지 않는다.** 서버 2를 유일한
  최신 기준으로 보존하고 쓰기를 멈춘 뒤 최신 상태를 복귀 대상에 전달·검증한다.
- 어느 단계든 두 CA 동시 실행 가능성·상태 공백이 해결되지 않으면 발급을 중지하고 수동 조사한다.

서버 1이 복구돼도 CA는 비활성으로 유지한다. 자신의 서버 인증서·코드·CRL·Foreman 연결을 검증한 뒤
Compiler로 재편입할 수 있다. CA를 다시 서버 1로 옮길 필요는 없으며, 필요 시 별도 계획된 승계로 수행한다.
CA 담당 목록·DNS·백업 작업과 설정 관리가 새 담당 서버를 기준으로 동작하도록 갱신한다.

## 후속 구현과 리허설

- 내장 CA 배치·서비스 설정의 실서버 검증, 암호화 백업·무결성 확인·상태 변경 후 보존 자동화
- 복구 담당 IAM/KMS/DNS 권한, 서버 1 fencing 및 복귀 후 CA 비활성 보장
- 두 Compiler CRL 반영과 Foreman CA Proxy 재연결 검증
- 서버 1 중단, 백업 공백, DNS 지연, 서버 2 재시작, 발급 후 복귀 실패 시나리오 리허설
- 실제 RTO/RPO 확정. 일일 백업 기반 수동 복구를 자동 Active/Standby로 표현하지 않음

관련 설계: [인증서·HA](HA_AND_CERTIFICATES.md), [단계별 구축](PHASED_ROLLOUT.md),
[LB·접속 경로](LB_AND_SCALING.md), [아키텍처](ARCHITECTURE_GUIDE.md).
근거: [OpenVox 백업·복구](https://docs.openvoxproject.org/openvox-server/latest/backup_restore.html),
[인증서 갱신·재발급](https://docs.openvoxproject.org/openvox-server/9.x/certificate_renewal.html),
[CRL 반영](https://docs.openvoxproject.org/openvox-server/latest/crl_refresh.html).

## 고도화 전략: API Gateway + Lambda 인증·CA 연계

직접 PAT 등록을 API Gateway + Lambda의 CSP 신원 검증/등록 대행으로 전환하는 항목은 TODO다.
추후 Foreman 등록과 CA CSR 승인·폐기를 관리 API로 연계하고 구성 요소별 실패 상태를 기록한다.
CA 발급자 자체 교체는 서명 키·발급 상태·CRL·갱신과 Puppet 프로토콜/기존 인증서 호환성을 검증한 뒤
결정한다. API Gateway/Lambda만으로 내장 CA의 모든 역할이 대체되지는 않는다.
장애 시 API Gateway·Lambda·비밀 저장소·CA 서비스의 상태와 재시도/멱등성도 별도 점검하도록 확장한다.
