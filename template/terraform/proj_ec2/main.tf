
 module "ec2" {
    providers = {
        aws = aws.common-poc-apn2
    }
    source = "../modules_v2/computing/instance"

    for_each = local.instances
    instance = each.value
}

module "sg" {
    providers = {
        aws = aws.common-poc-apn2
    }
    source = "../modules_v2/computing/sg"

    sg = local.sg
    ingress = local.ingress
    egress = local.egress
}
