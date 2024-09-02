output "form_endpoint_url" {
  value = aws_apigatewayv2_api.form.api_endpoint
}

output "github_repository_name" {
  value = github_repository.frontend.name
}

output "github_pages_url" {
  value = github_repository.frontend.pages.0.html_url
}

output "git_clone_url" {
  value = github_repository.frontend.git_clone_url
}

output "lambda_hash" {
  value = aws_lambda_function.form.source_code_hash
}