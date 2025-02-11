#############################################################################################
/*
# Security Group Configuration
1. Security Group
2. Ingress Rule
3. Egress Rule
*/
#############################################################################################

locals {
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Security Group
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_security_group" "main" {
    name        = var.sg.name 
    description = var.sg.description 
    vpc_id      = var.sg.vpc_id
    tags        = var.sg.tags
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Ingress Rule
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_security_group_rule" "ingress" {
    for_each = var.ingress

    security_group_id = aws_security_group.main.id
    type = "ingress"

    from_port   = each.value.from_port
    to_port     = each.value.to_port
    protocol    = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Egress Rule
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_security_group_rule" "egress" {
    for_each = var.egress
    
    security_group_id = aws_security_group.main.id
    type = "egress"

    from_port   = each.value.from_port
    to_port     = each.value.to_port
    protocol    = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
}



variable "ec2_instance" {
    description = "EC2 Instance Variable"
    # default = 
    type = map(object({
        description = optional(string, null)

        instance_name   = string
        instance_type   = string
        image_name      = string
        key_name        = optional(string, null)

        # Network
        subnet_id       = string
        vpc_security_group_ids  = list(string)

        


        placement_group         = optional(string, null)
        placement_partition_number = optional(string, null)

        # Option
        tenancy                 = optional(string, "default")
        disable_api_termination = optional(bool, true)
        disable_api_stop        = optional(bool, false)
        instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"

        # Option - Neccessary
        ## Metadata
        http_endpoint   = optional(string, "enabled")   # "enabled", "disabled"
        http_tokens     = optional(string, "required")  # "required", "optional"
        http_put_response_hop_limit = optional(number, 2)
        instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
        tags                        = optional(map(string), null)
    }))

}






resource "ec2_instance" "this" {
  for_each = var.ec2_instance

  name = "instance-${each.key}"

  instance_type          = "t2.micro"
  key_name               = "user1"
  monitoring             = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id              = "subnet-eddcdzz4"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}