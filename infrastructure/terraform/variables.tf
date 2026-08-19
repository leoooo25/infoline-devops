# infrastructure/terraform/variables.tf — inputs du projet (région, nom du cluster)
variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "cluster_name" {
  description = "Nom du cluster Kubernetes"
  type        = string
  default     = "infoline-cluster"
}
