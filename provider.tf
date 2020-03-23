provider "aws" {
  region  = var.aws_region
  version = "~> 2.47"

  # Configurar aqui o profile da AWS - caso utilize
  profile = var.aws_profile

  # Configurar aqui os tokens da AWS - caso utilize
  # aws_access_key = var.access_key
  # aws_secret_key = var.secret_key

}
