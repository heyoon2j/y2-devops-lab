variable "sg" {
    description = "Security Group Information"
    type = list(object({
        name                    = string
        description             = string
        vpc_id                  = string
    }))
}
