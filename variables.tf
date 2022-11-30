variable "region" {
  description = "Region for deploy web servers"
  default     = "us-west-2"
}

variable "instance_type" {
  description = "Instance type for home menu ci/cd"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment for home menu ci/cd: dev, prod"
  type        = string
  default     = "dev"
}

variable "default_cidr_blocks" {
  description = "Default cidr blocks value 0.0.0.0/0"
  default     = ["0.0.0.0/0"]
}
