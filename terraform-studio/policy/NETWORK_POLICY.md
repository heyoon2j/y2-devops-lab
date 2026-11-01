# AWS 네트워크 정책

- 버전: 검토 초안 v0.7 · 작성 2026-10-27 · 수정 2026-10-30
- 목적: 여러 시스템에서 재사용할 네트워크 정책 기준과 현재 시스템의 아키텍처별 적용 기준 정립
- 상태: 현재 운영 구조는 사용자 설명을 기준으로 기록. 설계 정책은 검토 초안이며 자동 검증·인프라 적용 전

## 문서 구성

| 찾고 싶은 내용 | 위치 |
| --- | --- |
| 현재 사용하는 연결 구조 | 1. 현재 운영 기준 |
| VPC·서브넷·주소 배치 및 향후 DMZ | 2. 네트워크 배치 정책 |
| IDC 연결·라우팅·방화벽 검사 | 3. 연결 및 검사 정책 |
| NACL·SG 구성 방식 | 4. 접근 제어 정책 |
| 통신별 허용·차단 기준 | 5. 통신 허용 기준 |
| 담당·로그·예외 처리 | 6. 운영 및 변경 관리 |
| 코드 반영과 검증 | 7. Terraform 구현 기준 |
| 아직 확인하거나 결정할 내용 | 8. 구현 전 결정 사항 |

- **현재 운영**: 확인된 운영 방향. 개별 회선·장비 설정까지 실측한 의미는 아님
- **설계 정책**: 아래의 허용·금지·필수 항목은 정책 채택 시 준수할 기준
- **권장**: 기본 설계안. 변경 시 사유를 기록
- **미정**: 8절에서 관리. 실제 값 확인 전 코드에 임의 반영하지 않음

## 1. 현재 운영 기준

### 1.1 적용 범위 및 인터넷 출구

| 대상 | 적용 기준 |
| --- | --- |
| 현재 통합 네트워크에 속한 PRD·DEV 등 환경 | 환경에 관계없이 IDC 인터넷 출구 원칙 동일 적용 |
| 같은 아키텍처를 사용하는 예외 VPC | 현재 시스템의 연결·출구 기준 적용 |
| TGW 미연결 등 독립 아키텍처의 예외 VPC | 별도 관리 문서로 적용 범위·연결·출구·보안 기준 정의 |

- VPC가 TGW에 연결되지 않았다는 이유만으로 인터넷 직접 출구를 자동 허용하지 않음
- 독립 예외 VPC의 구체적인 출구·연결 방식은 해당 문서에서 정의하며 현재 문서의 IDC/TGW/VGW 구성을 일괄 강제하지 않음

**현재 시스템의 연결 방향**

| 구분 | 현재 기준 |
| --- | --- |
| 인터넷 출구 | IDC만 사용 |
| AWS 유입 | `IDC → DX → TGW → 대상 VPC` |
| AWS 유출 | `각 VPC → 해당 VPC의 VGW → IDC` |
| 경로 분리 목적 | 트래픽 비용 제어 |
| 방향 정의 | 신규 연결 시작 주체가 아닌 AWS 경계 기준의 패킷 방향 |

### 1.2 운영 사실과 추가 설계의 경계

- 위 구조는 현재 통합 네트워크에 적용하며, 해당 범위에는 AWS 직접 인터넷 출구를 추가하지 않음
- 인터넷 요청·응답 모두 IDC의 승인된 보안 정책을 적용
- VGW 이후 회선 방식, NAT 위치, 실제 응답 경로는 **미확인** 상태로 관리
- AWS 보안 검사 VPC와 AWS DMZ는 **추가 설계 대상**이며 현재 배치된 것으로 가정하지 않음


### 1.3 다른 시스템에서의 재사용 및 문서 구분

| 문서 구분 | 다룰 내용 | 재사용 기준 |
| --- | --- | --- |
| 공통 네트워크 정책 | 접근 제어 원칙, SG/NACL의 역할, 주소 중복 방지, 소유권·감사·예외 관리 | 다른 시스템에서도 적용 가능 여부를 검토해 재사용 |
| 시스템별 네트워크 아키텍처·적용 문서 | 대상 환경·계정·VPC, 실제 연결·출구·검사 경로, 공통 정책 적용 범위 | IDC/DX/TGW/VGW 등 구체적인 연결 방식은 해당 시스템에 한해 적용 |
| 독립 예외 VPC 관리 문서 | 독립 관리 사유·담당자, 토폴로지, 인터넷 출구, 보안 통제, 공통 정책과의 차이 | 공통 정책 중 적용·비적용·대체 통제를 항목별 명시 |

- 현재 문서는 공통 기준과 현재 시스템 적용안을 함께 담은 검토 초안임
- IDC 출구와 TGW/VGW 경로는 현재 시스템의 기준이며 모든 시스템의 공통 원칙으로 일반화하지 않음
- 다른 시스템의 문서에서는 공통 기준을 참조하고 시스템별 연결 구조를 별도로 정의
- 독립 예외 VPC 문서는 대상 VPC·환경·담당자와 공통 정책의 차이를 명시하여 연결
- 검토 확정 범위: 적용 범위·문서 구분·PRD/DEV VPC 분리·프로젝트별 서브넷 공유·기본 Endpoint 서브넷·TGW 전용 서브넷 분리·PoC 독립망/별도 인터넷 출구. 그 외 세부 정책은 순차 검토 대상

## 2. 네트워크 배치 정책

### 2.1 VPC 구분

| 유형 | 용도 | 배치 기준 |
| --- | --- | --- |
| 공유 VPC | 동일 환경·신뢰 경계의 프로젝트 수용 | 프로젝트별 전용 서브넷 공유 |
| 보안 검사 VPC | AWS 측 추가 방화벽 검사 | 도입 범위 확정 후 생성; 업무 리소스·인터넷 출구 배치 금지 |
| 예외 VPC | 별도 격리·규제·라우팅·제품 제약 대응 | 통합망 참여 시 본 시스템 기준 적용; 독립 운영 시 별도 관리 문서로 정의 |

**공유 및 격리 기준**

- ‘공유’는 계정 간 서브넷 공유를 의미하며 인터넷 공개를 의미하지 않음
- 서브넷 배정 단위: `프로젝트 × 역할 × AZ`
- **확인된 운영**: PRD와 DEV는 별도 공유 VPC로 분리하고, 각 VPC에서 프로젝트별 서브넷을 생성해 공유
- 서로 다른 프로젝트의 동일 서브넷 사용은 예외 승인 필요
- AWS RAM 공유 전제: 동일 AWS Organizations 조직 및 서비스별 공유 서브넷 지원 확인
- 비용 검토 범위: TGW 처리량, 회선, AZ 간 전송, 방화벽, 로그

### 환경별 적용 범위

| 환경 | 확인 상태 | VPC 및 연결 기준 |
| --- | --- | --- |
| PRD | 현재 운영 | PRD 공유 VPC; 프로젝트별 서브넷 공유; IDC 출구 기준 적용 |
| DEV | 현재 운영 | DEV 공유 VPC; 프로젝트별 서브넷 공유; IDC 출구 기준 적용 |
| Sandbox | 추가 가능성 검토 중 | 추가 여부·VPC 분리·통합망 참여·인터넷 출구 모두 미정 |
| PoC | 독립 외부망 환경으로 확인 | PRD·DEV 및 IDC 내부망과 분리; 별도 인터넷 출구 사용; 별도 관리 문서로 상세 정의 |

- Sandbox와 PoC를 같은 환경으로 취급하지 않음
- PoC는 현재 통합망의 IDC 인터넷 출구 강제 대상에서 제외하며, 인터넷 출구·보안 통제·연결 구조는 별도 관리 문서로 정의
- PoC의 CIDR 종류, 계정/VPC 구성, 구체적인 인터넷 연결 방식은 아직 미정
- 아래 2~7절의 IDC/TGW/VGW 기반 연결 기준은 현재 통합망 기준이며 PoC에 일괄 적용하지 않음; 공통 보안 기준은 별도 문서에서 적용 범위 명시
- Sandbox의 통합망 참여 및 출구 기준은 미정

### 2.2 서브넷 구성

| 분류 | 역할 | 기본 배치 | 접근·연결 기준 |
| --- | --- | --- | --- |
| 업무 | LB | IDC에서 접근하는 private LB | 승인된 진입점의 서비스·health check 포트 |
| 업무 | APP | 애플리케이션·EKS 노드 | 공인 IP 금지; 필요한 외부 통신만 IDC 경유 |
| 업무 | DB | DB·캐시 | 공인 IP·인터넷 기본 경로 금지 |
| 연결 | TGW attachment | 채택 기준: 사용하는 AZ별 전용 서브넷 분리 | 현재는 전용 서브넷 없음; 기존 구성 확인 후 변경 계획 수립 |
| 검사 | Firewall / GWLBE | AWS 검사 도입 시 | 업무망과 분리; 인터넷 egress용 NAT 용도 금지 |
| 운영 | Endpoint | 공유 VPC의 기본 서브넷 | 프로젝트 공통 인프라로 관리; endpoint policy 적용 |
| 운영 | Resolver / Management | 기능별 필요 시 | DNS 전달·관리 접근 범위 명시 |
| 확장 | DMZ | 현재는 주소·정책만 예약 | 실제 생성 조건은 2.4 적용 |

**현재 구성과 채택한 설계 기준**

- 프로젝트 업무 서브넷은 기존 기준인 LB / APP / DB로 기록. 이번 설명의 `LB / APP / LB`가 DB를 의미하는지는 확인 필요
- Endpoint 서브넷은 공유 VPC에 기본 배치하며 프로젝트마다 중복 생성하는 구성으로 가정하지 않음

| 구분 | AWS 구성상 요구 | 채택한 전용 서브넷 기준 |
| --- | --- | --- |
| TGW | VPC attachment가 사용할 AZ마다 서브넷 1개 선택; AWS 기능상 기존 서브넷 사용도 가능 | 사용하는 AZ별 전용 attachment 서브넷 분리; 프로젝트 업무·Endpoint 서브넷과 분리 |
| VGW | VPC에 직접 연결 | 전용 서브넷 불필요 |

- TGW 전용 서브넷의 목적: 연결 구간과 업무 구간의 라우팅·NACL·주소 사용 책임 분리
- 일반 공유 VPC에도 적용하며 Inspection VPC만의 기준이 아님
- 전용 서브넷에 업무 리소스·Endpoint를 배치하지 않음; 분리 자체가 방화벽 검사·격리를 제공하는 것은 아님
- 신규 설계 시 작은 CIDR(예: /28)을 검토하되 실제 크기는 주소 계획에서 결정
- 기존 환경은 현재 attachment 서브넷·AZ·route table·NACL 확인 후 분리 변경 영향과 전환·원복 계획 수립; 정책 채택과 실제 인프라 변경 완료를 구분
- TGW attachment NACL은 AWS 권고의 양방향 개방 모델을 검토하고, 업무 서브넷·SG에서 세부 통제; 최종 프로파일은 NACL 정책 검토 시 결정
- 근거: [TGW attachment 생성](https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html), [TGW 설계 권고](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-best-design-practices.html), [VGW 연결](https://docs.aws.amazon.com/vpn/latest/s2svpn/SetUpVPNConnections.html)

**공통 배치 기준**

- 필요한 역할만 생성; 모든 VPC에 동일 서브넷을 일괄 생성하지 않음
- PRD는 최소 2개 AZ 권장; 계정 간 AZ 대응은 AZ ID로 확인
- EKS는 노드·Pod·제어 평면 ENI의 IP 수요를 별도로 산정
- VGW는 VPC에 연결하며 별도 VGW 서브넷을 생성하지 않음
- internet-facing LB/public subnet은 자동 생성하지 않음; AWS 직접 공개가 필요하면 ingress 정책 별도 변경

### 2.3 주소 및 DNS 관리

- **주소 할당**: IPAM 또는 중앙 CIDR 대장으로 VPC·프로젝트·역할·AZ·DMZ 예약 대역 관리
- **중복 방지**: VPC·IDC·VPN·연결 대상·예약 대역 전체 검사
- **보조 CIDR 추가**: local 경로, TGW/VGW/IDC 광고, 방화벽, NACL, SG, 할당량 영향 검토
- **IPv6**: 초기 예제는 비활성; 도입 시 IDC 출구·검사·`::/0` 정책 별도 정의
- **DNS**: 승인된 Resolver 전달 경로 사용; 무제한 재귀·전달 루프 금지
- **DNS 필터링**: AmazonProvidedDNS는 SG/NACL만으로 차단할 수 없으므로 필요 시 Resolver DNS Firewall 검토

### 2.4 DMZ 확장 준비

| 구분 | 지금 준비할 내용 | 도입 시 적용할 기준 |
| --- | --- | --- |
| 주소 | AZ별 전용 CIDR·명명 규칙 예약 | APP/DB·IDC·확장 대역과 중복 금지 |
| 배치 | 공유 VPC 전용 서브넷 / 독립 DMZ VPC 후보 관리 | 격리 요구와 IDC DMZ 역할 분담에 따라 선택 |
| 역할 | ingress proxy·reverse proxy·relay 후보 정의 | 승인된 경계 서비스만 배치 |
| 라우팅 | 전용 route table·연결 프로파일 설계 | 업무망 기본 경로 상속·무조건 연결 금지 |
| 보안 | 전용 NACL·SG 프로파일 설계 | DMZ → APP 승인 포트만 허용; DB 직접 연결 금지 |
| 인터넷 | IDC 출구 원칙 유지 | DMZ 명칭만으로 공인 IP·public subnet·IGW 허용 금지 |

- 현재는 실제 DMZ 서브넷·라우트·허용 규칙을 생성하지 않음
- 활성화 전 NAT·TLS 종료·원본 IP·health check·MTU·타임아웃·양방향 검사 검토
- 로그·가용성·원복 기준 승인 후 활성화
- IDC DMZ의 실제 위치·공개 진입점·NAT·TLS·검사 역할은 별도 확인

## 3. 연결 및 검사 정책

### 3.1 라우팅 통제

- 인터넷 허용 서브넷·목적지에 한해 VGW 경유 경로 구성; DB 등 불필요 계층에 기본 경로 일괄 생성 금지
- IDC CIDR 광고, TGW association/propagation, VPC route table을 함께 관리
- 가장 긴 prefix 및 동일 prefix의 static/propagated 우선순위 확인
- TGW·VGW 연결만으로 유입·유출 방향이 강제된다고 가정하지 않음
- IGW·public NAT Gateway·egress-only IGW 등 AWS 직접 인터넷 출구 생성 금지
- 장애 시에도 승인된 IDC 대체 경로로 복구; AWS 직접 인터넷 우회 금지
- AWS 사설 서비스용 VPC Endpoint는 인터넷 출구와 구분하고 endpoint policy 적용

**DX 구성 관리**

- TGW용 transit VIF와 VGW용 private VIF 구성을 구분
- 동일 DX Gateway에 TGW·VGW를 동시에 연결하는 설계 금지
- 회선·VIF·DX Gateway·VPN 연결 관계를 연결 대장으로 관리

### 3.2 방화벽과 SG/NACL의 역할

| 통제 지점 | 담당 범위 | 설계상 주의점 |
| --- | --- | --- |
| IDC 방화벽 | 인터넷 출입 및 현재 경계 통제 | NAT·HA를 포함해 왕복 세션 인식 확인 |
| AWS 방화벽 | 추가로 지정한 검사 범위 | TGW 유입·VGW 유출 양쪽 검사 가능 여부 확인 |
| SG | 리소스 접근 | 같은 VPC의 프로젝트 격리 포함 |
| NACL | 서브넷 경계 보조 통제 | 동일 서브넷 내부 통신에는 미적용 |

### 3.3 비대칭 경로와 검사 조건

- 현재 AWS 측 구조는 `DX/TGW 유입 + VGW 유출`로 경로가 다름
- 인터넷발·APP발·IDC발 통신의 요청과 응답을 각각 추적
- IDC 방화벽·NAT의 세션 인식, HA 상태 동기화, NAT 매핑, 관측 IP, 장애 전환 확인
- IDC 검사 위치가 같아도 왕복이 같은 상태 추적 도메인을 거치는지 검증

**AWS 방화벽을 추가하는 경우**

- 유입만 검사하고 VGW 유출은 우회하는 구성 금지
- AWS NFW: 요청·응답을 동일 endpoint로 전달할 수 있는 토폴로지에서 사용
- Palo Alto: 제품·HA 방식의 비대칭 처리 조건 검증
- TGW appliance mode만으로 TGW/VGW로 갈라진 경로가 해결된다고 가정하지 않음
- 양방향 검사 설계를 확정한 뒤 제품·배포 모델 구현

**같은 VPC 내부를 검사하는 경우**

- local 통신은 중앙 검사 VPC를 자동으로 통과하지 않음
- 기본 프로젝트 격리는 SG로 수행
- 방화벽 검사가 필수면 VPC 분리 또는 지원되는 내부 middlebox routing 별도 설계
- 같은 서브넷 통신을 TGW/NACL로 검사한다고 가정하지 않음

## 4. 접근 제어 정책

### 4.1 공통 원칙

- 신규 연결은 기본 거부; 승인된 출발지·목적지·프로토콜·포트만 허용
- 사설 IP·같은 프로젝트라는 이유로 전체 신뢰하지 않음
- 실제 통신 허용 범위는 5절에서 관리; SG와 NACL에는 각자의 동작 방식에 맞게 반영

### 4.2 NACL 구성

- **대역**: RFC1918 전체 대신 실제 연결·승인 대역 목록 사용
- **프로파일**: LB / APP / DB / attachment / firewall / 향후 DMZ 구분
- **내부 전체 포트 허용**: 필요 시 명시적 프로파일로 정의하고 방화벽·SG의 세부 통제 지점 기록
- **응답**: 상태 비저장 방식이므로 요청·응답 양방향 규칙 작성
- **포트**: ephemeral 범위는 OS·LB·NAT 요구로 확정; 단일 임의 범위로 고정하지 않음
- **관측 IP**: IDC NAT·프록시 전후 IP/포트와 LB client IP 보존 여부 기록
- **공인 상대**: IDC 경유만으로 사설 IP가 되는 것은 아니므로 공인 대역 일괄 차단 금지
- **운영 통신**: health check·DNS 전달·모니터링·MTU/PMTUD ICMP 검토
- **평가 순서**: 낮은 번호부터 평가; 미일치 트래픽 최종 거부

### 4.3 SG 구성

| 종류 | 구성 단위 | 허용 목적 |
| --- | --- | --- |
| 리소스 SG | 개별 리소스 | 해당 리소스에만 필요한 추가 통신 |
| 모듈 SG | 동일 서비스의 기능·신뢰 경계 | 모듈 멤버 간 승인된 내부 통신 |
| 역할 공통 SG | 프로젝트/서비스별 LB·APP·DB | 보안 솔루션·모니터링 등 공통 운영 통신 |

**모듈 및 공통 SG 적용**

- 모듈은 Terraform 디렉터리가 아닌 업무 기능 단위
- 기본 예제는 필요한 포트만 허용
- 내부 자유 통신은 동일 모듈 SG self-reference의 명시적 선택 프로파일로 제공
- PRD 자유 통신은 구성원·필요성 검토 후 적용
- 프로젝트·환경·LB/APP/DB에 관행적으로 같은 모듈 SG를 부착하지 않음
- 역할 공통 SG에 전체 운영망·모든 사설망·all-port를 기본 허용하지 않음

**규칙 작성 시 제약**

- 여러 SG는 허용 규칙의 합집합; 리소스 SG로 다른 SG의 허용을 축소할 수 없음
- 초기 전체 egress 허용을 그대로 사용하지 않고 필요한 목적지·포트 명시
- 지원되는 직접 통신은 SG 참조 우선; middlebox/NAT/TGW 경로의 참조 제약 별도 검토
- SG만으로 VGW 경유를 강제할 수 없으므로 3.1 라우팅 정책과 함께 적용
- 업무 배포에 VPC 기본 SG 사용 금지
- 운영 접근은 SSM 등 승인된 경로 사용; endpoint/IDC 연결도 함께 정의

## 5. 통신 허용 기준

- 아래 ‘허용’도 실제 대역·포트·담당자 확정 후 적용; 표에 없는 신규 연결은 기본 거부
- `APP_PORT`·`DB_PORT`는 미정 값이며 실제 규칙 생성 전 확정
- 상태 추적 응답과 신규 inbound 허용을 구분하고 NACL 응답 규칙을 별도로 작성

### 5.1 서비스 및 공통 운영 통신

| 출발지 | 목적지 | 결정 | 허용 범위 / 조건 |
| --- | --- | --- | --- |
| IDC 승인 진입점 | private LB | 승인 후 허용 | 서비스·필요한 health check 포트 |
| LB | 해당 APP | 승인 후 허용 | APP_PORT·health check |
| APP | 해당 DB | 승인 후 허용 | DB_PORT; 승인된 관리 주체도 필요한 DB 포트만 허용 |
| 동일 모듈 멤버 | 동일 모듈 멤버 | 승인 후 허용 | 선택한 모듈 프로파일 |
| 다른 프로젝트 | 서비스 진입점 | 기본 거부 | 양측 승인 후 API 포트만 허용 |
| 보안·모니터링 솔루션 | 지정 리소스 | 승인 후 허용 | 솔루션별 포트 |
| 워크로드 | AWS Endpoint·DNS·운영 서비스 | 승인 후 허용 | 필요한 서비스별 범위 |

### 5.2 외부 통신 및 금지 경계

| 통신 | 결정 | 경로 / 조건 |
| --- | --- | --- |
| APP → 인터넷 | 기본 거부 | 승인 목적지·서비스만 VGW → IDC 경유 허용 |
| 인터넷 응답 → APP | 허용된 세션의 응답 | IDC → DX → TGW 복귀 경로는 실측 확인 대상 |
| DB → 인터넷 | 기본 거부 | 대체 경로 검토 후 만료 있는 예외 승인 |
| 연구개발망 → PRD | 기본 거부 | 상시 허용 금지; 만료 있는 예외만 허용 |
| 인터넷 → AWS 직접 공개 진입점 | 기본 구성에서 금지 | ingress 정책 변경 별도 검토 |
| LB·향후 DMZ → DB | 금지 | 데이터 계층 직접 연결 차단 |
| 향후 DMZ → APP | 승인 후 허용 | 승인된 서비스 포트만 허용 |
| 인터넷 전체 → SSH/RDP | 금지 | 승인된 운영 접근 경로 사용 |

- APP 외부 API 호출의 검증 예시:
  - 요청: `APP → VGW → IDC → 인터넷 API`
  - 응답 후보: `인터넷 API → IDC → DX → TGW → APP`
  - 실제 응답 경로는 NAT·BGP·회선·서브넷 라우팅 확인 후 확정

## 6. 운영 및 변경 관리

### 6.1 담당과 소유권

| 담당 | 관리 범위 |
| --- | --- |
| 네트워크 | VPC·CIDR·서브넷·RAM·TGW·VGW·라우팅·NACL |
| 보안 | 방화벽 정책·검사 범위·예외 검토 |
| 서비스 | 참여 계정 소유 리소스·SG |
| IDC | 회선·BGP·방화벽·NAT·DMZ·인터넷 출구 |

- 공유 VPC 소유자는 네트워크, 참여자는 자신이 소유한 SG·리소스 관리
- 공통 SG는 소유 계정·RAM 공유 조건 명시; 소유자가 참여자 SG를 임의 수정한다고 가정하지 않음

### 6.2 감사 및 예외 처리

- **로그**: VPC/TGW Flow Logs, 방화벽, LB, 변경 이력의 수집 지점 정의
- **판정**: Flow Logs ACCEPT만으로 방화벽 통과·애플리케이션 정상 처리 판정 금지
- **예외 기록**: ID·환경·담당자·사유·5-tuple·왕복 경로·검사 여부·대체 통제·승인자·만료일·원복 방법
- **정기 검토**: 미사용 규칙·만료 예외 제거; 보관 기간·알림·검토 주기는 8절에서 확정

## 7. Terraform 구현 기준

### 7.1 리소스 소유권

| 위치 | 책임 |
| --- | --- |
| `tf-network/accounts` | VPC·서브넷·RAM·NACL·TGW/VGW 연결·라우팅 |
| `tf-workload/accounts` | 공유 서브넷 참조·워크로드·참여 계정 소유 SG |
| `tf-modules/network/security-group` | 명시적 입력에 따른 규칙 생성; 숨은 전체 허용 금지 |
| 도메인 interfaces | 역할·모듈 프로파일 조합 |

- AWS NAT/IGW를 기본 예제로 생성하지 않고 IDC 연결 입력 사용
- VGW의 실제 DX/VPN 연결 방식 확정 전 회선 구성을 임의 생성하지 않음
- DMZ는 예약 CIDR·역할만 정의하고 기본 비활성
- 같은 리소스를 여러 state에서 중복 관리하지 않음
- 예제 CIDR·포트를 실환경 값과 구분
- 방화벽 제품·토폴로지 미확정 구성을 배포 가능한 것으로 표시하지 않음

### 7.2 완료 및 검증 기준

- [ ] 허용 외부 통신이 IDC를 경유하고 AWS 직접 출구가 없는지 확인
- [ ] 요청·응답을 IDC NAT/방화벽 및 AWS 로그로 함께 추적
- [ ] 구체적인 prefix·BGP 변경에 따른 TGW/VGW 실제 경로 확인
- [ ] DB 인터넷·미승인 프로젝트 통신·연구개발망 → PRD 차단 확인
- [ ] SG 합집합·참조 제약, NACL 응답·순서, LB health check 확인
- [ ] CIDR 추가 및 회선/AZ/방화벽 장애 시 보안 정책·IDC 출구 유지 확인
- [ ] DMZ 예약 대역의 무단 사용 및 리소스 자동 활성화가 없는지 확인
- [ ] fmt/validate와 실제 도달성·차단 검증을 구분
- [ ] plan/apply 및 실환경 테스트는 문서 작성과 별도 작업으로 수행

## 8. 구현 전 결정 사항

| 분류 | 확인·결정할 내용 | 담당 협의 |
| --- | --- | --- |
| 환경 확장 | Sandbox 도입 여부·연결 기준; PoC 계정/VPC·CIDR·별도 출구 방식·보안 통제 및 관리 문서 작성 | 네트워크·서비스·보안 |
| TGW 서브넷 | 현재 attachment의 선택 서브넷·AZ, 전용 CIDR·NACL·변경 영향·전환/원복 계획 | 네트워크·보안 |
| 실제 연결 | 서브넷 route table·IDC prefix/BGP·VGW 이후 회선/VIF/DX Gateway/VPN 구성 | 네트워크·IDC |
| 왕복 세션 | 인터넷·IDC발 요청/응답 4개 방향, NAT 위치·HA 상태 공유 | 네트워크·IDC·보안 |
| 공개 진입점 | IDC 공개 진입점·프록시·TLS 종료·private LB 연결 | IDC·서비스·보안 |
| AWS 검사 | 검사 VPC 도입 여부·제품·양방향 검사·프로젝트 간 필수 검사 범위 | 네트워크·보안 |
| 주소·격리 | 환경·프로젝트·AZ별 CIDR·VPC 격리·DMZ 예약 대역과 배치 | 네트워크·서비스·IDC |
| 접근 프로파일 | 모듈 자유 통신·PRD 적용 조건·운영/보안 대역·포트·NACL | 서비스·보안·네트워크 |
| 운영 | 장애 대체 경로·복구 목표·로그 보관·알림·검토 주기 | 네트워크·IDC·보안 |

## 부록. AWS 공식 참고 자료

- 기존 문서의 근거 링크를 유지한 참고 목록이며, 이번 개정은 문서 분류·중복 정리를 위한 편집임

- [VPC 공유](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-sharing.html)
- [TGW 요금](https://aws.amazon.com/transit-gateway/pricing/)
- [VPC 경로 우선순위](https://docs.aws.amazon.com/vpc/latest/userguide/route-tables-priority.html)
- [VIF 유형](https://docs.aws.amazon.com/directconnect/latest/UserGuide/WorkingWithVirtualInterfaces.html)
- [DX Gateway와 TGW 제약](https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-transit-gateways.html)
- [TGW 설계 권고](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-best-design-practices.html)
- [VPC CIDR 제약](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html)
- [NACL 제한](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
- [NFW 비대칭 라우팅 제약](https://docs.aws.amazon.com/network-firewall/latest/developerguide/asymmetric-routing.html)
- [VPC 라우팅 옵션](https://docs.aws.amazon.com/vpc/latest/userguide/route-table-options.html)
- [NACL 동작](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
- [NACL 규칙 예제](https://docs.aws.amazon.com/vpc/latest/userguide/custom-network-acl.html)
- [SG 규칙](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)
- [middlebox와 SG 참조 제약](https://docs.aws.amazon.com/vpc/latest/userguide/middlebox-routing-console.html)
- [공유 VPC 책임](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-share-limitations.html)
- [SG 공유 조건](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-sharing.html)
