# Terraform Workload Repository

## Overview
이 저장소는 멀티 AWS Account 환경에서 workload domain 리소스를 관리하기 위한 Terraform repository이다.

## Managed Resources
- Amazon EKS
- Amazon DynamoDB
- Amazon ECR
- Workload Security Group

## Repository Structure

accounts → projects → interfaces → modules

## Layer Responsibilities

### modules
- 순수 resource 정의
- variables.tf / outputs.tf 포함
- provider/backend 금지

### interfaces
- module orchestration
- 조건문 / 반복문 / feature flag 처리

### projects
- service blueprint
- default metadata
- default feature
- nested merge

### accounts
- provider
- backend
- account metadata
- override only

## Execution
terraform init
terraform plan
terraform apply

## Rules
- Network 리소스 생성 금지
- IAM authoritative 리소스 생성 최소화
- Shared resources는 data source lookup 사용
