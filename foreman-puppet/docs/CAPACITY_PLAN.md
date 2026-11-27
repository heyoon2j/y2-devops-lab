# AWS 배치와 노드 규모에 따른 단계별 구성

## 확인한 요구와 결정 상태

| 항목 | 상태 |
| --- | --- |
| 개발 관리 서버 위치 | AWS 확정. 리전·VPC·서브넷·CSP 간 연결은 미정 |
| 개발 관리 대상 | 1,000대 이상, 2,000대 이하 |
| 운영 관리 대상 | 약 250대 |
| 초기 검증 | 환경별 LB + Server1 + 로컬 PostgreSQL 16, 대표 소수 Agent 검증 |
| 운영 | 같은 고정 2대 + LB 구조. 공용 RDS Multi-AZ 권장 |
| Autoscaling | 고도화로 보류. 현재 고정 대수 수동 운영 |
| 설치 방식 | EC2 VM에 OS 패키지 직접 설치를 권장. 컨테이너 필수 요구는 없음 |
| 점검 주기 | 권장 초안은 30분 + splay. 실제 Agent 설정은 아직 배포하지 않음 |

여기서 개발은 실험용 소규모라는 의미가 아니다. 개발의 총 노드 수가 운영보다 많으므로
용량은 환경 이름이 아닌 실제 요청량으로 산정한다. 고정 EC2 2대는 3단계 배치 목표이며 전체 2,000대 처리량이 검증된 사양은 아니다.

[개발·운영 공통 LB와 Autoscaling 경계](LB_AND_SCALING.md),
[Agent 실행 옵션](AGENT_OPERATIONS.md)을 함께 적용한다.

## VM과 컨테이너 비교

| 항목 | EC2 + OS 패키지 | 컨테이너 |
| --- | --- | --- |
| 초기 설치 | foreman-installer와 OS 서비스 중심으로 구성 | 이미지·네트워크·볼륨·구성 요소별 실행 방식을 별도로 설계 |
| 운영 확인 | systemd·패키지·서비스 로그를 직접 확인 | 컨테이너 및 오케스트레이터의 로그·상태·업그레이드 절차 필요 |
| 영구 상태 | DB·인증서·CA 상태·코드·설치 설정을 백업 | 같은 상태를 영구 볼륨/외부 서비스로 보존해야 함 |
| 확장 | 별도 Compiler VM과 DB 분리 | Compiler 확장 배포가 가능하지만 코드·인증·DB 정책도 필요 |
| 이번 권장 | VM 직접 설치 | 조직의 표준 컨테이너 운영 요구가 생기면 재검토 |

컨테이너 자체가 Catalog 컴파일·Foreman DB 처리량을 높여주는 것은 아니다.
직접 설치도 Ansible/설치 자동화로 재현하고, 승인한 commit으로 코드 배포를 반복할 수 있다.
설치 방법은 처리 용량·HA 설계와 구분한다.

## 1단계: 개발·운영 각각 LB + Server1 + 로컬 PostgreSQL

Foreman·Compiler·Smart Proxy·DB를 같은 EC2에 두고 소수 Agent를 검증한다.
8 vCPU·32 GiB RAM·100 GiB SSD는 공동 배치의 시작 후보이며 확정 사양/성능 보장이 아니다.
처음에는 1~몇 대부터 연결하고 대표 OS·Role로 확대한다. 단일 서버로 전체 2,000대 처리를 보장하지 않는다.
백업은 EC2 밖에 보존한다. 설치 입력과 완료 기준은 [단계별 구축](PHASED_ROLLOUT.md)을 따른다.

## 2단계: 각 환경의 로컬 DB를 RDS로 이전

기존 LB와 Server1을 유지하고 각 환경 DB를 각각 RDS PostgreSQL 16으로 이전한다.

## 3단계: Server2 추가·N-1 부하 검증

각 환경에 다른 AZ의 Server2를 추가해 기존 LB에 편입한다.
이후 고정 2대 구조에서 실제 Profile로 노드 수를 단계적으로 늘린다.
한 EC2가 중단되면 남은 EC2가 Foreman과 Compiler 부하를 함께 처리하므로 N-1 상태도 측정한다.
Foreman API·DB가 병목이면 Compiler만 늘리지 않고 해당 계층과 사양을 조정한다.
부족할 경우 수동 증설 또는 Compiler 전용 서버 분리를 검토하며 ASG는 고도화 전까지 도입하지 않는다.

## 운영 약 250대의 용량 기준

개발과 같은 고정 2대 + LB + 공용 HA DB 운영 방식을 사용한다.
운영은 요청량이 작더라도 한 대 장애 시의 복구·가용성 기준과 CA 전환을 검증해야 한다.
250대라는 수치만으로 개발보다 무조건 작은 인스턴스를 선택하지 않는다.

## 30분 주기 가정의 요청량

`평균 Catalog 실행 요청/초 = 노드 수 ÷ 실행 주기(초)`

| 환경 | 노드 수 | 평균 Catalog 실행 요청/초 | 하루 실행 수 |
| --- | ---: | ---: | ---: |
| 개발 | 1,000 | 약 0.56 | 48,000 |
| 개발 | 2,000 | 약 1.11 | 96,000 |
| 운영 | 250 | 약 0.14 | 12,000 |

균등 분산된 경우의 계산이며 전체 HTTP 요청량은 아니다. 각 실행의 Facts 업로드,
ENC 조회, 파일 전송, Report 처리, 재시도와 최초 등록 요청이 추가된다.
컴파일 시간이 길수록 같은 평균 요청량에도 더 많은 동시 처리 자원이 필요하다.
Agent 실행 주기·splay와 최초 user-data 등록의 배치/지연을 별도로 설계한다.

Report/Facts 크기와 보존 기간을 정하고 DB 쓰기·정리 비용을 측정한다.
하루 96,000회 실행이라는 계산만으로 필요한 저장소 GB를 확정하지 않는다.

## 단계별 측정 및 수용 기준

- 대표 OS·Role·CSP의 실제 Profile로 Catalog 크기와 평균/상위 지연 컴파일 시간 측정
- Compiler CPU·메모리·JVM heap/GC·JRuby 대기 시간과 요청 큐 확인
- Foreman ENC/Facts/Report 지연·오류율, 웹/API 응답 시간 확인
- PostgreSQL CPU·IO·연결 수·잠금·복제/정리 작업·디스크 증가량 측정
- Agent 실행이 목표 주기 안에 완료되는지와 backlog가 누적되지 않는지 확인
- 10~50대 기능 검증 후 단계적으로 확대. 재부팅/등록 집중과 대량 코드 변경 시점도 시험
- 운영은 한 계층의 한 대가 중단된 N-1 상태에서 목표 주기와 수용 가능한 지연을 만족하는지 검증

수용 가능한 오류율·상위 지연·RTO/RPO 기준을 정하고 측정 결과로 사양·대수·주기를 확정한다.
현재 저장소의 960개 Catalog 조합 테스트는 기능 검증이며 이 부하 시험을 대신하지 않는다.

## 확인할 다음 항목

1. VM 직접 설치 권장안 채택 여부와 설치 엔진/버전
2. Agent 실행 주기·실행 시간 분산·일괄 등록 규모
3. AWS 리전·VPC·사설 접속·GCP/KC와의 연결·조직 DNS
4. 개발/운영의 Report 보존 기간·예산·RTO/RPO
5. EC2 2대·RDS 사양과 전체 규모 확대 시 수동 증설/역할별 분리 시점

## 참고

- [Puppet Server 튜닝과 JRuby 자원](https://help.puppet.com/core/current/content/puppetcore/server/tuning_guide.htm)
- [Puppet Server 성능 지표](https://help.puppet.com/core/current/content/puppetcore/server/puppet_server_metrics_performance.htm)
- [OpenVox Server 튜닝](https://docs.openvoxproject.org/openvox-server/8.x/tuning_guide.html)
- [Foreman 공식 패키지 설치 가이드](https://docs.theforeman.org/5.0/Quickstart/index-foreman-deb.html)
