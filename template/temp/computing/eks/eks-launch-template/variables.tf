variable "name_prefix" { type = string }
variable "image_id" { type = string default = null }
variable "volume_size" { type = number default = 50 }
variable "volume_type" { type = string default = "gp3" }
variable "user_data" { type = string default = null }
variable "tags" { type = map(string) default = {} }
