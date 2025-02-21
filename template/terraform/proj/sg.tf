


locals {
    sg = {
        name = "test-sg"
        description = "40022-all"
        vpc_name = ""
        tags = {        
            Name = "test-sg"
        }
    }

    ingress = {
        all = {
            from_port        = 0
            to_port          = 40022
            protocol         = "tcp"     # == "all"
            cidr_blocks      = ["0.0.0.0/0"]
        }
    }

    egress = {
        all = {
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
        }
    }
}