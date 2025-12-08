variable "db_name"          { type = string }
variable "username"         { type = string }
variable "password"         { type = string }
variable "subnet_ids"       { type = list(string) }
variable "vpc_id"           { type = string }
variable "app_sg_id"        { type = string }
variable "backup_retention" { type = number }
