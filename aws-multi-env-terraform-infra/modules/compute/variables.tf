variable "public_subnet_ids"  { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id"          { type = string }
variable "app_sg_id"          { type = string }
variable "instance_type"      { type = string }
variable "app_name"           { type = string }
variable "vpc_id"           { type = string }

