# Scenario 1: Repair the PAYNOTIFY Statements Bucket

## Overview

PAYNOTIFY stores customer statements in the S3 bucket **<inject key="StatementsBucket" />**. A security review found that the bucket is not protected from public access and keeps no previous versions of files. On top of that, uploads to the **statements** folder have failed since the change window.

In this scenario, you will secure the bucket, turn on versioning, remove the policy that blocks uploads, and prove that uploads work again.

## Scenario

_**Security Lead:** The statements bucket failed our review. Public access is not blocked and there is no versioning._

_**You (Cloud Engineer):** I will lock it down, turn on versioning, and find out why uploads to the statements folder are failing._

## Task 1: Repair the Statements Bucket

In this task, you will fix the bucket settings and confirm that a statement file can be uploaded.

### Challenge

Repair the bucket **<inject key="StatementsBucket" />** so that it meets the following requirements:

1. All public access to the bucket is blocked.
1. Bucket versioning is enabled.
1. The cause of the failing uploads to the **statements/** folder is found and removed.
1. A file named **test-statement.txt** containing the text below is uploaded to the **statements/** folder.

   ```
   PAYNOTIFY test statement
   ```

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at <a href="https://support.cloudlabs.ai/isv">https://support.cloudlabs.ai/isv</a>. We are available 24/7 to help you out.

<validation step="867593d6-415b-46a2-aaed-0a050c98e259" />

## Summary

In this scenario, you:

- Turned on Block all public access for the bucket.
- Removed a bucket policy that denied uploads to the statements folder.
- Enabled bucket versioning.
- Uploaded a test statement to prove the fix.

Click the **Next** button to begin Scenario 2.
