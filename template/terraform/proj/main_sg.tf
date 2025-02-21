locals {
    sg = {
        name            = "test-sg"
        vpc_name        = ""
        default_tags    = local.default_tags
    } 
    ingress = {
        ssh = {
            from_port       = 40022
            to_port         = 40022
            protocol        = "tcp"
            cidr_ipv4       = "255.255.255.255/32"
        }
    }

    egress  = {
        all ={ 
            from_port       = 0
            to_port         = 0
            protocol        = "-1"
            cidr_ipv4       = "0.0.0.0/0"
        }
    }
 
}

module "sg" {
    providers = {
        aws = aws.cloud-poc-apn2
    }
    source = "../modules_v2/computing/sg"

    sg = local.sg
    ingress = local.ingress
    egress = local.egress
}
