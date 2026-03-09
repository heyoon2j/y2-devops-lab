# Architecture

## Domain Ownership

### Network Domain
- Shared Subnet
- Network ACL
- Baseline Security Group
- Transit Gateway
- Firewall

### IAM Domain
- IAM Role
- IAM Policy
- SSO Permission Set
- Trust Policy

### Workload Domain
- Amazon EKS
- Amazon DynamoDB
- Amazon ECR
- Service Security Group

## Shared Resource Consumption

### Subnet Lookup
tag 기반 조회

### Baseline Security Group Lookup
tag 기반 조회

### IAM Role Lookup
name 기반 조회

## Naming Convention
org-domain-env-service-purpose

예시:
temp-workload-dev-zootopia-eks
temp-workload-prd-zootopia-dynamodb
temp-network-shared-baseline-sg

## Override Policy

허용:
- feature on/off
- sizing 변경
- count 변경

금지:
- module topology 변경
- security baseline 제거
- ownership boundary 침범
