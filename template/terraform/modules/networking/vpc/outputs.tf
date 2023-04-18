output "vpc" {
    description = "VPC Information"
    sensitive = true

    value = {
        id = aws_vpc.vpc-proj.id
        name = "vpc-${var.proj_name}-${var.proj_env}-${var.proj_region}"
    }
}

output "attachment_subnet" {
    description = "Information for TGW"
    sensitive = true
    value = [for s in data.aws_subnet.attahment : s.id]
}

