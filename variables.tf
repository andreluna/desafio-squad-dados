variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "terraform"
}

variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "bucket_name" {
  default = "projeto-maxmilhas-desafio"
}

variable "workgroup" {
  default = "maxmilhas_desafio"
}

variable "database_name" {
  default = "desafio_maxmilhas"
}

variable "glue_catalog_table" {
  default = "pesquisas"
}
