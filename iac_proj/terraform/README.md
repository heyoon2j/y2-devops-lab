# Terraform Example
* This project has multiple environment and Separated directory structure
* 

## 
1. Create __immutable resource__ using Terraform.
    * ELB (NLB, ALB)
    * EKS
    * S3
    * EFS
    * VPC
    * Transit Gateway
    * CloudFront
    * IAM
2. Don't create __mutable resource__ using Terraform. Because Terraform state will conflict with aws resource state, create resouce using cli or others.
    * EC2 Instance (Auto Scaling)
    * RDS
    * Redis
    * Redshift
3. Don't manage __AWS Managed Service__ using Terraform. Use services by console.
    * Organization
    * Route53
    * Backup
    * CloudWatch
    * CloudTrail
* Create resources for each project. Because 
* 



## Directory Structure
* qwer

* ebs
* efs
* s3





## Directory Structure (Separated)
* Ref: https://stackoverflow.com/questions/66024950/how-to-organize-terraform-modules-for-multiple-environments
```
iac_proj/
├─ packer/
├─ ansible/
├─ terraform/
│  ├─ env/
│  │  ├─ dev/
│  │  │  ├─ apps/
│  │  │  │  ├─ blog/
│  │  │  ├─ data/
│  │  │  │  ├─ s3-blog/
│  │  │  ├─ network/
│  │  ├─ prd/
│  │  │  ├─ apps/
│  │  │  │  ├─ blog/
│  │  │  │  ├─ ecommerce/
│  │  │  ├─ data/
│  │  │  │  ├─ efs-ecommerce/
│  │  │  │  ├─ rds-ecommerce/
│  │  │  │  ├─ s3-blog/
│  │  │  ├─ general/
│  │  │  │  ├─ main.tf
│  │  │  ├─ network/
│  │  │  │  ├─ main.tf
│  │  │  │  ├─ terraform.tfvars
│  │  │  │  ├─ variables.tf
│  │  ├─ stg/
│  │  │  ├─ apps/
│  │  │  │  ├─ ecommerce/
│  │  │  │  ├─ blog/
│  │  │  ├─ data/
│  │  │  │  ├─ efs-ecommerce/
│  │  │  │  ├─ rds-ecommerce/
│  │  │  │  ├─ s3-blog/
│  │  │  ├─ network/
│  ├─ modules/
│  │  ├─ apps/
│  │  │  ├─ blog/
│  │  │  ├─ ecommerce/
│  │  ├─ common/
│  │  │  ├─ acm/
│  │  │  ├─ user/
│  │  ├─ computing/
│  │  │  ├─ alb/
|  |  |  ├─ nlb/
│  │  ├─ networking/
│  │  │  ├─ tgw/
│  │  │  ├─ vpc/
│  │  ├─ storage/
│  │  │  ├─ efs/
│  │  │  ├─ s3/
├─ tools/
```


## Directory Structure (Monolithic)
```
project/
├─ modules/
│  ├─ acm/
│  ├─ app-blog/
│  ├─ app-ecommerce/
│  ├─ server/
│  ├─ vpc/
├─ vars/
│  ├─ user/
│  ├─ prod.tfvars
│  ├─ staging.tfvars
│  ├─ test.tfvars
├─ applications.tf
├─ providers.tf
├─ proxy.tf
├─ s3.tf
├─ users.tf
├─ variables.tf
├─ vpc.tf
```