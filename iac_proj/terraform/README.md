# Terraform Example
* This project has multiple environment and Separated directory structure
* 

## 
* Create __immutable resource__ using Terraform. Because Terraform state will conflict with aws resource state.
    > EC2 Instance(Auto Scaling) / RDS etc
* Create resources for each project. Because 
* 


## (Current Project)
```
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
  │  │  ├─ network/
  ├─ modules/
  │  ├─ apps/
  │  │  ├─ blog/
  │  │  ├─ ecommerce/
  │  ├─ common/
  │  │  ├─ acm/
  │  │  ├─ user/
  │  ├─ computing/
  │  │  ├─ alb/
  |  |  ├─ nlb/
  │  ├─ networking/
  │  │  ├─ tgw/
  │  │  ├─ vpc/
  │  ├─ storage/
  │  │  ├─ efs/
  │  │  ├─ s3/
```



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