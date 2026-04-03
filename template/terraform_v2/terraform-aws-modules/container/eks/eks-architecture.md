# EKS Architecture (Production)

## Cluster
- Private Endpoint
- Auto Mode: Disable
- KMS Encryption: Enable

## Network
- AWS VPC CNI
- IPv4
- Service CIDR: 172.20.0.0/16

## Core Add-ons
- vpc-cni
- kube-proxy
- coredns
- aws-load-balancer-controller
- aws-ebs-csi-driver

## Optional Add-ons
- amazon-cloudwatch-observability

## Logging
- Fluent Bit → S3

### Fluent Bit Config

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

## Security
- IRSA required
- KMS encryption

## Summary
Production-ready EKS with full control and cost optimization
