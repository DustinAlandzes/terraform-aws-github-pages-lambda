# terraform-aws-github-pages-lambda
Terraform module for quickly creating a website with a form you can submit

## Usage

1. Set up authentication for the aws and github providers (For example, set the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and GITHUB_TOKEN environment variables)
    * https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    * https://registry.terraform.io/providers/integrations/github/latest/docs#authentication
2. Add these requirements and the module to your GitHub configuration:
```

terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.65.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.3"
    }
  }
}

module "terraform_aws_github_pages_lambda" {
    aws_region = "us-east-1"
    github_repository_name = "test"
    email = "your-email@goes-here.tld"
}
```