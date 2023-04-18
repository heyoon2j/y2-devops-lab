module "network" {
    source = "./modules/networking"
    providers = {
        aws = aws.aps1
    }
}


module "server" {
    source = "./modules/server"
}


module "auth" {
    source = "./modules/auth"
}


module "auth" {
    source = "./modules/auth"
}