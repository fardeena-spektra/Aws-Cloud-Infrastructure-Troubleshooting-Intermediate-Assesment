# Scenario 2: Repair the PAYNOTIFY Notification Function

## Overview

The Lambda function **<inject key="LambdaFunctionName" />** sends payment notifications and writes a record of each one to the **notifications** folder of the S3 bucket **<inject key="StatementsBucket" />**. Since the change window, every run of the function fails.

In this scenario, you will test the function, read each error, fix it, and run the function until it succeeds.

## Scenario

_**Incident Manager:** No payment notifications have gone out since last night. The notification function fails every time._

_**You (Cloud Engineer):** I will run a test event, fix each error it reports, and keep going until the function succeeds._

## Task 1: Repair the Notification Function

In this task, you will fix the function configuration and its permissions until a test run succeeds.

### Challenge

Repair the function **<inject key="LambdaFunctionName" />** so that it meets the following requirements:

1. A test event named **pn-test** with the event JSON below runs successfully and returns **statusCode 200**.

   ```
   {
     "customer": "demo-customer"
   }
   ```

1. The function writes its notification record to the bucket **<inject key="StatementsBucket" enableCopy="true"/>**.
1. The function execution role is allowed to write to the **notifications/** folder of that bucket only, through an inline policy named **pn-notify-s3-write**.
1. The file **notifications/latest.json** is present in the bucket **<inject key="StatementsBucket" />**.

> **Note:** IAM changes can take a few seconds to apply. If you still see AccessDenied, wait a moment and test again.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at <a href="https://support.cloudlabs.ai/isv">https://support.cloudlabs.ai/isv</a>. We are available 24/7 to help you out.

<validation step="84ddac2c-b102-4077-b3ae-1b4b4ec66b66" />

## Summary

In this scenario, you:

- Fixed the function handler so Lambda can find the entry point.
- Pointed the BUCKET_NAME environment variable at the correct bucket.
- Gave the execution role permission to write notification records to S3.
- Ran the function successfully end to end.

Click the **Next** button to begin Scenario 3.
