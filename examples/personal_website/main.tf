module "terraform_aws_github_pages_lambda" {
  source = "../.."
  email  = "fezf00+terraform-module@gmail.com"
  github_repository_name = "personal-website"
}