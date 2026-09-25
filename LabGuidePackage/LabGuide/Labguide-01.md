# Scenario 1: Repair the PAYNOTIFY Statements Bucket

### Duration: 20 Minutes

## Overview

PAYNOTIFY stores customer statements in the S3 bucket **<inject key="StatementsBucket" />**. A security review found that the bucket is not protected from public access and keeps no previous versions of files. On top of that, uploads to the **statements** folder have failed since the change window.

In this scenario, you will secure the bucket, turn on versioning, remove the policy that blocks uploads, and prove that uploads work again.

## Scenario

_**Security Lead:** The statements bucket failed our review. Public access is not blocked and there is no versioning._

_**You (Cloud Engineer):** I will lock it down, turn on versioning, and find out why uploads to the statements folder are failing._

## Task 1: Repair the Statements Bucket

In this task, you will fix the bucket settings and confirm that a statement file can be uploaded.

1. In the AWS Management Console, search for **S3 (1)** in the search bar and select **S3 (2)**.

   ![](../media/s1-t1-01.png)

1. Select the bucket **<inject key="StatementsBucket" /> (1)**.

   ![](../media/s1-t1-02.png)

1. Open the **Permissions (1)** tab. Under **Block public access (bucket settings)**, notice that it is **Off (2)**. Select **Edit (3)**.

   ![](../media/s1-t1-03.png)

1. Select **Block all public access (1)** and select **Save changes (2)**. Type **confirm (3)** and select **Confirm (4)**.

   ![](../media/s1-t1-04.png)

1. On the same **Permissions** tab, scroll to **Bucket policy (1)**. The policy has a statement **FreezeStatementUploads (2)** that denies **s3:PutObject** for everyone on the **statements/** folder. It was left over from the change freeze.

   ![](../media/s1-t1-05.png)

1. Select **Delete (1)** next to the bucket policy, type **delete (2)** and select **Delete (3)**.

   ![](../media/s1-t1-06.png)

1. Open the **Properties (1)** tab. Under **Bucket Versioning**, notice that it is **Disabled (2)**. Select **Edit (3)**.

   ![](../media/s1-t1-07.png)

1. Select **Enable (1)** and select **Save changes (2)**.

   ![](../media/s1-t1-08.png)

1. On the virtual machine, open **Notepad**, type the text below, and save the file on the **Desktop** as **test-statement.txt**.

   ```
   PAYNOTIFY test statement
   ```

   ![](../media/s1-t1-09.png)

1. Return to the bucket, open the **Objects (1)** tab and select **Create folder (2)**. Enter **statements (3)** as the folder name and select **Create folder (4)**.

   ![](../media/s1-t1-10.png)

1. Open the **statements/ (1)** folder and select **Upload (2)**. Select **Add files (3)**, choose **test-statement.txt** from the Desktop, and select **Upload (4)**.

   ![](../media/s1-t1-11.png)

1. Confirm that the upload shows **Succeeded (1)** and that **test-statement.txt** is listed in the **statements/** folder **(2)**.

   ![](../media/s1-t1-12.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.<validation step="REPLACE-WITH-S1-T1-VALIDATION-ID" />

## Summary

In this scenario, you:

- Turned on Block all public access for the bucket.
- Removed a bucket policy that denied uploads to the statements folder.
- Enabled bucket versioning.
- Uploaded a test statement to prove the fix.

Click the **Next** button to begin Scenario 2.

### Happy Assessing !!
