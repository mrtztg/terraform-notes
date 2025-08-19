variable "region" {
  default     = "eu-west-2"
  type        = string
  nullable    = false
  description = "Region of infra"
}

variable "aws_profile" {
  default     = "terraform"
  type        = string
  description = "AWS CLI aws_profile to use. It should be defined before using here."
}

variable "ami_filter" {
  type = object({
    filter = string,
    owner  = string
  })
  description = "AMI filter"
}

variable "ec2_instance_configs" {
  type = list(object({
    instance_type = string,
    tenancy       = string
  }))
}

variable "ec2_port" {
  type        = number
  default     = 8080
  description = "Exposed ports of EC2 instances"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of s3 bucket"
}

variable "db_config" {
  type = object({
    db_name           = string,
    instance_type     = string,
    allocated_storage = number
  })
}

variable "db_credentials" {
  sensitive = true
  type = object({
    username = string,
    password = string
  })
}

variable "alb_security_group_name" {
  type = string
}

variable "ec2_security_group_name" {
  type = string
}