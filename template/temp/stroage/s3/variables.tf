variable "bucket_name" {
  type = string
}

variable "sse_algorithm" {
  type    = string
  default = "AES256"
}

variable "tags" {
  type    = map(string)
  default = {}
}