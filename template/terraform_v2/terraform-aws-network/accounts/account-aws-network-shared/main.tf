module "network" {
  source = "../../interfaces/network/vpc-three-tier"

  vpc_cidr = "192.168.10.0/24"
  vpc_name = "dev-vpc"

  features = {
    subnet = true
    nacl   = false
  }

  subnets = {
    app-a = {
      cidr_block        = "192.168.10.0/26"
      availability_zone = "ap-northeast-2a"
      map_public_ip_on_launch = false
    },
    app-c = {
      cidr_block        = "192.168.10.64/26"
      availability_zone = "ap-northeast-2c"
      map_public_ip_on_launch = false
    }
  }

  tags = {
    Environment = "dev"
  }
}
