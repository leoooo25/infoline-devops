# infrastructure/terraform/main.tf — cluster EKS + Lambda de login
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Récupère le VPC par défaut du compte AWS
data "aws_vpc" "default" {
  default = true
}

# Récupère les sous-réseaux du VPC par défaut
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ─────────────────────────────────────────
# CLUSTER KUBERNETES (EKS)
# ─────────────────────────────────────────

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # Accessible depuis internet (pour les démos)
  cluster_endpoint_public_access = true

  # 1 seul nœud pour minimiser les coûts
  eks_managed_node_groups = {
    main = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

# ─────────────────────────────────────────
# LAMBDA — SERVICE DE LOGIN SERVERLESS
# ─────────────────────────────────────────

# Rôle IAM : permission que la Lambda peut s'exécuter
resource "aws_iam_role" "lambda_role" {
  name = "infoline-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Zippe automatiquement le code Python
data "archive_file" "login_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/login.py"
  output_path = "${path.module}/lambda/login.zip"
}

# Fonction Lambda
resource "aws_lambda_function" "login" {
  function_name    = "infoline-login"
  role             = aws_iam_role.lambda_role.arn
  handler          = "login.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.login_zip.output_path
  source_code_hash = data.archive_file.login_zip.output_base64sha256
}
