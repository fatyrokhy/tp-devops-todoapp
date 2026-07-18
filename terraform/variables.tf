variable "aws_region" {
  description = "Region AWS ou deployer l'infrastructure"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "Plage d'adresses IP du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Plage d'adresses IP du sous-reseau public (Front)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Plage d'adresses IP du sous-reseau prive (Back + DB)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_ip" {
  description = "Adresse IP de l'administrateur autorisee en SSH (format CIDR, ex: 1.2.3.4/32)"
  type        = string
}

variable "public_key_path" {
  description = "Chemin vers la cle publique SSH"
  type        = string
}

variable "instance_type" {
  description = "Type d instance EC2"
  type        = string
  default     = "t3.micro"
}