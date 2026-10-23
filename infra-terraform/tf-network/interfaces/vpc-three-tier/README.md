# vpc-three-tier

network 도메인의 조합 모듈입니다. accounts의 배포 루트에서 호출합니다.
backend나 provider 구성을 소유하지 않으며, provider 설정은 호출자로부터 전달받습니다.
구현 시 variables.tf, outputs.tf, versions.tf를 추가합니다.
