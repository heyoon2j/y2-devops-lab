variable "cluster" {
  type = object({
    name             = string
    subnets          = list(string)
    role_arn         = string
    kms_key_arn      = string
  })
}