
module "provider" {
    source = "./config"
}

module "ec2" {
    provider = aws.apn2
    source = "./modules_v2/computing/instnace"

    
}