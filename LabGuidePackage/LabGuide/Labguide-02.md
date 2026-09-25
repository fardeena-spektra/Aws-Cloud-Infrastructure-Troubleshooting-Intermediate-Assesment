# Scenario 2: Repair the PAYNOTIFY Notification Function

### Duration: 25 Minutes

## Overview

The Lambda function **<inject key="LambdaFunctionName" />** sends payment notifications and writes a record of each one to the **notifications** folder of the S3 bucket **<inject key="StatementsBucket" />**. Since the change window, every run of the function fails.

In this scenario, you will test the function, read each error, fix it, and run the function until it succeeds.

## Scenario

_**Incident Manager:** No payment notifications have gone out since last night. The notification function fails every time._

_**You (Cloud Engineer):** I will run a test event, fix each error it reports, and keep going until the function succeeds._

## Task 1: Repair the Notification Function

In this task, you will fix the function configuration and its permissions until a test run succeeds.

1. In the AWS Management Console, search for **Lambda (1)** and select **Lambda (2)**.

   ![](../media/s2-t1-01.png)

1. Select the function **<inject key="LambdaFunctionName" /> (1)**.

   ![](../media/s2-t1-02.png)

1. Open the **Test (1)** tab. Enter **pn-test (2)** as the event name, replace the event JSON with the text below **(3)**, and select **Test (4)**.

   ```
   {
     "customer": "demo-customer"
   }
   ```

   ![](../media/s2-t1-03.png)

1. The run fails with **Handler 'handler' missing on module 'index' (1)**. Open the **Code (2)** tab and notice that the function in **index.py** is named **lambda_handler (3)**.

   ![](../media/s2-t1-04.png)
   ![](../media/s2-t1-04.1.png)

1. On the **Code** tab, scroll to **Runtime settings (1)** and select **Edit (2)**. Change **Handler** to **index.lambda_handler (3)** and select **Save (4)**.

   ![](../media/s2-t1-05.png)
   ![](../media/s2-t1-05.1.png)


1. Return to the **Test (1)** tab and select **Test (2)** again. The run now fails with an S3 error **(3)** because the function writes to a bucket named **pn-statements-archive**, which does not belong to this environment.

   ![](../media/s2-t1-06.png)

1. Open the **Configuration (1)** tab, select **Environment variables (2)** and select **Edit (3)**.

   ![](../media/s2-t1-07.png)

1. Change the value of **BUCKET_NAME** to the value below **(1)** and select **Save (2)**.

   ```
   <inject key="StatementsBucket" />
   ```

   ![](../media/s2-t1-08.png)

1. Return to the **Test (1)** tab and select **Test (2)** again. The run now fails with **AccessDenied (3)** on **PutObject**. The function execution role is not allowed to write to the bucket.

   ![](../media/s2-t1-09.png)
   ![](../media/s2-t1-09.1.png)

1. Open the **Configuration (1)** tab, select **Permissions (2)**, and select the role name under **Execution role (3)**. The IAM console opens.

   ![](../media/s2-t1-10.png)

1. On the role page, select **Add permissions (1)** and select **Create inline policy (2)**.

   ![](../media/s2-t1-11.png)

1. Select **JSON (1)**, replace the content with the policy below **(2)**, and select **Next (3)**.

   ```
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "WriteNotifications",
         "Effect": "Allow",
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::<inject key="StatementsBucket" />/notifications/*"
       }
     ]
   }
   ```

   ![](../media/s2-t1-12.png)

1. Enter **pn-notify-s3-write (1)** as the policy name and select **Create policy (2)**.

   ![](../media/s2-t1-13.png)

1. Return to the Lambda function, open the **Test (1)** tab and select **Test (2)**. The run now shows **Succeeded (3)** and returns **statusCode 200**.

   ![](../media/s2-t1-14.png)

   > **Note:** IAM changes can take a few seconds to apply. If you still see AccessDenied, wait a moment and test again.

1. In the S3 console, open the bucket **<inject key="StatementsBucket" />** and confirm that **notifications/latest.json (1)** is present.

   ![](../media/s2-t1-15.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="f03d9cb8-b472-4e41-84a3-9abd3f5a6fdb" />

## Summary

In this scenario, you:

- Fixed the function handler so Lambda can find the entry point.
- Pointed the BUCKET_NAME environment variable at the correct bucket.
- Gave the execution role permission to write notification records to S3.
- Ran the function successfully end to end.

Click the **Next** button to begin Scenario 3.

### Happy Assessing !!
