# Terraform Starter Template v2

```bash
terraform-workload/
├── modules/
│   └── workload/
│       ├── eks/
│       ├── dynamodb/
│       ├── ecr/
│       └── service_sg/
│
├── interfaces/
│   └── platform/
│
├── projects/
│   └── zootopia/
│
└── accounts/
    ├── temp-aws-zootopia-dev/
    └── temp-aws-zootopia-prd/
```

## Example Flow
accounts → projects → interfaces → modules

## Dev Override
- node_count = 1

## Prd Override
- node_count = 3

## Shared Resources Lookup
- shared subnet via tag lookup
- baseline SG via data source
- IAM role via data source
