## MetaData
Question Type : Single Choice

## Question
5. dev-app must now upload files to the S3 bucket dev-reports, but it gets AccessDenied. What is the correct fix?

## Options
Option 1 : Create an IAM user with access keys and save the keys in a file on the dev-app instance.

Option 2 : Make the dev-reports bucket public so that any instance in the VPC is able to write to it.

Option 3 : Add s3:PutObject for objects in the dev-reports bucket to the dev-app-role IAM policy.

Option 4 : Attach sg-dev-app to the dev-reports bucket so the instance is allowed to write objects.

## Answers
Option 3 : 2

## Number of Retries
1
