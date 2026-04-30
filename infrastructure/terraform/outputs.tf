output "cluster_name" {
  value = module.eks.cluster_name
}

output "lambda_function_name" {
  value = aws_lambda_function.login.function_name
}
