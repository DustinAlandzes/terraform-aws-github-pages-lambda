terraform {
  required_version = "~> 1.9.5"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
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

provider "aws" {
  region = var.aws_region
}

# https://advancedweb.hu/how-to-use-unique-resource-names-with-terraform/#:~:text=There%20is%20a%20terraform%20resource,%7B%20function_name%20%3D%20%22%24%7Brandom_id.
resource "random_id" "id" {
  byte_length = 8
}

data "aws_iam_policy_document" "github_actions_update_pages_and_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:UpdateFunctionCode"]
    resources = [aws_lambda_function.form.arn]
  }
}

resource "aws_iam_user_policy" "github_actions_update_pages_and_lambda" {
  user   = aws_iam_user.github_actions_update_pages_and_lambda.name
  policy = data.aws_iam_policy_document.github_actions_update_pages_and_lambda.json
}

resource "aws_iam_user" "github_actions_update_pages_and_lambda" {
  name = random_id.id.hex
  path = "/system/"
}

resource "aws_iam_access_key" "github_actions_update_pages_and_lambda" {
  user = aws_iam_user.github_actions_update_pages_and_lambda.name
}

resource "github_repository" "frontend" {
  name       = var.github_repository_name
  visibility = var.github_repository_privacy

  template {
    owner      = "DustinAlandzes"
    repository = "aws-lambda-react-github-pages-template"
  }

  pages {
    build_type = "workflow"
  }
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = github_repository.frontend.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.github_actions_update_pages_and_lambda.secret
}

resource "github_actions_secret" "aws_access_key_id" {
  repository      = github_repository.frontend.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.github_actions_update_pages_and_lambda.id
}

resource "github_actions_variable" "aws_region" {
  repository    = github_repository.frontend.name
  variable_name = "AWS_REGION"
  value         = "us-east-1"
}

resource "github_actions_variable" "lambda_arn" {
  repository    = github_repository.frontend.name
  variable_name = "AWS_LAMBDA_FUNCTION_ARN"
  value         = aws_lambda_function.form.arn
}

resource "github_actions_variable" "contact_form_endpoint" {
  repository    = github_repository.frontend.name
  variable_name = "NEXT_PUBLIC_FORM_ENDPOINT"
  value         = aws_apigatewayv2_api.form.api_endpoint
}

resource "aws_lambda_permission" "allow_api_gw_invoke_authorizer" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.form.function_name
  source_arn    = "${aws_apigatewayv2_api.form.execution_arn}/*"
  principal     = "apigateway.amazonaws.com"
}

resource "aws_apigatewayv2_stage" "contact_form" {
  api_id      = aws_apigatewayv2_api.form.id
  name        = "$default"
  auto_deploy = true
  description = "Default stage (i.e., Production mode)"

  default_route_settings {
    throttling_burst_limit = 2
    throttling_rate_limit  = 2
  }
}

resource "aws_apigatewayv2_route" "form" {
  api_id    = aws_apigatewayv2_api.form.id
  route_key = "POST /"

  target = "integrations/${aws_apigatewayv2_integration.form.id}"
}

resource "aws_apigatewayv2_integration" "form" {
  api_id           = aws_apigatewayv2_api.form.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "API Gateway integration with Lambda for Contact Form"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.form.invoke_arn
}

resource "aws_apigatewayv2_api" "form" {
  protocol_type = "HTTP"
  description   = "API Gateway pointing to Lambda for contact form."
  name          = "Form"
  #   TODO
  #   cors_configuration {
  #     allow_origins = [""]
  #     allow_methods = ["POST"]
  #   }
}

data "archive_file" "lambda_code" {
  type        = "zip"
  source_file = "main.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "form" {
  filename      = data.archive_file.lambda_code.output_path
  function_name = random_id.id.hex
  description   = "Receives form submissions from my personal website and publishes them to SNS."
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler"
  memory_size   = 128
  timeout       = 4
  architectures = [
    "x86_64"
  ]
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.form.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
  ]
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_cloudwatch_log_group" "form" {
  name              = "/aws/lambda/${aws_lambda_function.form.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "iam_for_lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "give_lambda_permission_to_publish_to_sns" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [aws_sns_topic.form.arn]
  }
}

resource "aws_iam_policy" "form_lambda_sns" {
  path        = "/service-role/"
  description = "Give form lambda permission to publish to SNS."
  policy      = data.aws_iam_policy_document.give_lambda_permission_to_publish_to_sns.json
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.form_lambda_sns.arn
}

resource "aws_sns_topic_subscription" "personal_website_contact_form" {
  topic_arn = aws_sns_topic.form.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_sns_topic" "form" {
  fifo_topic = false
}