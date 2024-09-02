provider "aws" {
  region = "us-east-1"
}

variables {
  aws_region             = "us-east-1"
  github_repository_name = "terraform-test-repository"
  email                  = "fezf00+terraform-module@gmail.com"
}

run "setup" {
  # Create the S3 bucket we will use later.
}

run "verify" {

  # Check that the lambda hash matches
  assert {
    condition     = run.setup.lambda_hash == filebase64sha256("./lambda_function_payload.zip")
    error_message = "Lambda function has a different hash than main.py"
  }

  # Check that the github repository's name matches
  assert {
    condition     = run.setup.github_repository_name == var.github_repository_name
    error_message = "Lambda function has a different hash than main.py"
  }

  # Check that secrets and environment variables are set on the GitHub repository.
  # Submit the form on Github Pages and verify the sns topic was published to
}