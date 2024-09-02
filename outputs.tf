output "form_endpoint_url" {
  value       = aws_apigatewayv2_api.form.api_endpoint
  description = "API Gateway endpoint used to access Lambda"
}

output "github_repository_name" {
  value       = github_repository.frontend.name
  description = "The GitHub repository's name"
}

output "github_pages_url" {
  value       = github_repository.frontend.pages[0].html_url
  description = "The GitHub Pages URL"
}

output "git_clone_url" {
  value       = github_repository.frontend.git_clone_url
  description = "Git clone URL"
}

output "lambda_hash" {
  value       = aws_lambda_function.form.source_code_hash
  description = "Hash of the Lambda, used for testing"
}