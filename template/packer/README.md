```
template/packer
├── entrypoint.sh                # 단일 진입점. 클라우드/OS/아키텍처를 받아 Packer 빌드를 실행
├── aws/                         # AWS 전용 템플릿/변수/플러그인
│   ├── build.pkr.hcl             # aws 빌드 정의 (builder/provisioner 등)
│   ├── source.pkr.hcl            # ami, aws 리소스 등 source 블록 정의
│   ├── plugin.pkr.hcl            # 플러그인 및 공통 설정
│   └── variables/                # OS/아키텍처별 변수 파일
├── gcp/                         # GCP용 빌드 정의와 변수 디렉토리
│   ├── build.pkr.hcl
│   └── variables/
├── kc/                          # 자체 커스텀 클라우드(kc)용 템플릿
├── provisioners/                # 빌드한 이미지 내부에서 실행되는 스크립트/설정
│   ├── config/                   # 리포지토리/부트스트랩/rsyslog 설정
│   │   ├── bootstrap/            # 부트스트랩시 필요한 rsyslog 구성 등
│   │   └── repo/                 # yum/apt 리포지토리 정의 파일
│   ├── files/                    # 복사할 정적 파일
│   └── script/                   # 실제 빌드/초기화 스크립트
│       ├── common/               # 모든 OS 공통 init/설정 스크립트 (ssh, ntp, sysctl 등)
│       ├── os/                   # OS별 세부 설정 (ubuntu20/22/24, rocky8/9 등)
│       ├── utils/                # 여러 스크립트에서 공유되는 함수(common.sh)
│       ├── validation/           # 빌드 결과를 검증하는 쉘 스크립트
│       └── security/             # 보안 관련 스크립트 (서버 패치/서비스 관리)
```

## 핵심 흐름
1. `entrypoint.sh`에 `<CLOUD> <OS_NAME> <ARCH_TYPE>` (예: `aws ubuntu22 x86_64`) 를 전달하여 실행
2. `entrypoint.sh`가 해당 클라우드 디렉토리의 템플릿과 변수 파일(`variables/<os>-<arch>.pkrvars.hcl`, `variables/common.pkrvars.hcl`)을 조합
3. 공통 `provisioners/` 디렉토리의 스크립트와 설정을 포함한 Packer 빌드가 실행됨
4. 빌드 로그는 `packer_<cloud>_<os>_<arch>_<timestamp>.log`로 남고, 후속 S3 업로드용 변수(`s3_bucket`, `s3_path`)가 함께 적용

## entrypoint.sh 사용법
```bash
./entrypoint.sh <CLOUD> <OS_NAME> <ARCH_TYPE>
```
- `CLOUD`: `aws`, `gcp`, `kc` 중 하나
- `OS_NAME`: 지원되는 OS 이름 (예: `ubuntu20`, `ubuntu22`, `rocky8`, `rocky9`, `amazon2023`)
- `ARCH_TYPE`: `x86_64` 또는 `arm64`

예시:
```bash
./entrypoint.sh aws ubuntu22 x86_64
```

`entrypoint.sh`의 주요 작업:
1. 실행 파라미터 조합으로 템플릿/변수 경로(`aws`, `aws/variables`) 설정
2. `nohup packer build`를 호출하며 내부적으로 `ssh_username`, `ssh_password`, 로그/S3 관련 변수들을 함께 주입
3. `tee`로 로그를 파일(`packer_<cloud>_<os>_<arch>_<timestamp>.log`)로 남기면서 stdout에도 출력
4. 종료 상태를 확인하여 성공/실패 메시지를 출력하고 필요시 종료 코드 반환

이 구조를 참고하여 원하는 클라우드-OS 조합에 맞는 `*.pkrvars.hcl`을 편집하거나 새로운 provisioner를 추가하면 됩니다.