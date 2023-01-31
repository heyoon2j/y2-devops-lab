resource "aws_security_group" "sg-proj" {
    count = length(var.sg)
    
    name        = var.sg[count.index]["name"]
    description = var.sg[count.index]["description"]
    vpc_id      = var.sg[count.index]["vpc_id"]

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "${var.sg[count.index]["name"]}"
    }
}

