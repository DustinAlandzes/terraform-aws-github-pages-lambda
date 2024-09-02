def handler(event, context):
    """ This is an empty lambda to get an aws_lambda_function deployed with Terraform. """
    return {
        "statusCode": 200,
        "success": True,
    }
