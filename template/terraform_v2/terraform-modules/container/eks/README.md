# EKS Production Setup
- Name: prd-{project}-eks-cluster
- Support Mode: Standard Support
- Auto Mode: disable
- ControlPlane Scaling Tier: disable
- 삭제 방지: enable
- ARC: disable -> 수동으로 대응
- Network
    - Cluster ip family: IPv4
    - Cluster Endpoint: Private
    - Kubernetes 서비스 IP 주소 블록 구성: 172.20.0.0/16
    - Plugin: VPC CNI Plugin 사용 (추후에 LB IP모드 사용)
- Authentication & Authorization
    - API_AND_CONFIG_MAP
- Envelope Encryption
    - Enable -> prd-{project}-eks-cluster-key
- Monitoring
    - Node: Zabbix
    - Pod: CloudWatch container insights 활성화 ()
    - Network: Network Flow Monitoring Agent (Add-On)
- Logging
    - Fluent Bit DaemoSet (Add-On) -> 로그 저장 (ConfigMap 설정 수정필요)
    - Error Log: CloudWatch Logs
    - 모든 Log: S3
- Autoscaling (HPA)
    - metrics-server (Karpenter로 추후에 변경 가능)

---
## Core Add-ons
- vpc-cni
- coredns
- kube-proxy
- metrics-server
- aws-load-balancer-controller
- aws-ebs-csi-driver

---

## Optional Add-ons
- Network Flow Monitoring
- EKS Pod identity agent: Pod에 직업 권한 부여 가능, 기존에는 노드에 적용

---

## Fluent Bit S3 Config

```yaml
[OUTPUT]
    Name s3
    Match *
    bucket your-s3-bucket-name
    region ap-northeast-2
    total_file_size 50M
    upload_timeout 10m
    store_dir /tmp/fluent-bit/s3
    s3_key_format /logs/$TAG/%Y/%m/%d/%H/%M/%S
    compression gzip
```

---

## Architecture Summary
- Network: AWS VPC CNI
- Security: KMS + IRSA
- Logging: Fluent Bit → S3
- Ingress: ALB Controller
- Storage: EBS CSI


## Network
- 일반 모드(Instance): LB -> Node(EC2) -> iptables -> Pod
- IP 모드: LB -> Pod(ENI IP) 다이렉트 슛!
=> LB 생성 시, IP 모드 활성화 필요


## Authentication & Authorization
기존에는 aws-auth ConfigMap 수정이 필요했음. 하지만 이제는 IAM Service로 대신 적용시킬 수 있음
- k8s 경우, conf 파일의 인증서 + Role/ClusterRole 사용가능


## Envelope Encryption
- KMS: 데이터 키를 암호화시킬 키 관리
- etcd: 암호화된 데이터 키 + 암호화된 Secret Object(데이터 키에 암호화된)
    > 암호화된도 정보만 가지고 있는 아키텍처
- api server: 요청시 캐싱 여부 확인 -> 없다면 암호화된 데이터 키를 KMS에 복호화 요청 -> 복호화된 데이터 키 캐싱 + 복호화된 Secret Object를 Pod 등에 전달 

> k8s 경우, EncryptionConfiguration(암호화 설정 파일)을 만들어서 API Server의 실행 옵션에 적용





---

### Support Mode
- 표준 지원(Standard Support): 마이너 버전이 eks에 출시된 후, 최초 14개월 동안 제공 (오픈소스 k8s 커뮤니티의 기본지원과 동일)
    - 비용: $0.10
- 확장 지원(Extended Support): 표준 지원이 끝난 직후부터 추가로 12개월 동안 제공 (최대 26개월까지 유지)
    - 비용: $0.60
    - 확장 지원은 "버전 업그레이드를 제때 못해서 당장 서비스가 망가지는 건 막아줄주게, 대신 유지지봇수 비용은 훨씬 비싸게 받을게"라는 일종의 유예 기간 정책

> 중요한하 점은 표준지원 종료 후, 상위 버전으로 업그레이드하지 않으면 AWS Cluster가 강제로 확장 지원 상태로 넘어가버림. 그리고 자동으로 시간당 $0.60 요금을 자동으로 청구함(거부 불가!!)



### Auto Mode (자율 모드)
자동으로 노드 그룹을 관리함
- 내부적으로 Karpenter 기술 활용 / 자동으로 최적화된 리소스를 사용함
- 장점:
    - 강력한 보안과 21일 수명 주기(자동 롤링): 모든 Workser Node는 생성된지 최대 21일이 지나면 자동으로 노드를 교체함. 사용자가 일일이 OS 보안패치나 커널 업데이트를 신경 쓸 필요없이 항상 최신 보안 상태를 유지함
- 단점:
    - 커스텀 불가
    - 노드에 접속 불가 (SSH, 직접 접속을 차단하고 있음)
    - Pod 설계 주의: 수시로 노드를 껐다 켤 있으므로 주의 필요


### Control Plane Scaling Tier
EKS는 자동으로 Scale Up을 하지만, 반응형이기 때문에 속도가 느림. 그래서 이를 위해 미리 Provisioning
- etcd Size Limit
    - 표준 모드의 Control Plane은 클러스터의 상태를 저장하는 데이터베스스 용량이 최대 8GB로 제한되어 있음
    - 그래서 늘어난 Pod의 데이터가 8GB를 초과한 경우, 줄여놔야만 기본으로 돌릴 수 있음


### Application Recovery Controller(ARC) Zonal Shift(영역 전환)
AZ 장애 발생 시, 트래픽피을 장애가 발생한 Zone으로 보내지 않는다.
- Load Balancer에 붙어서 동작
- 수동으로 설정 가능: AWS Console -> Application Recovery Controller -> Zone Shift 탭 -> 리소스 선택 -> 전환 시작(Start zonal shift) -> AZ 및 타이머 설정 -> 실행