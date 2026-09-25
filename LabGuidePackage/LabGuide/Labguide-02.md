# Scenario 2: Repair the Private Application Tier

### Duration: 60 Minutes

## Overview

With the web tier back online, PAYNOTIFY still cannot send notifications. The private application instance **pn-app-01** runs a scheduled health check that must reach the internet, read and write objects in the S3 bucket **pn-appdata**, and open a connection to the MySQL database **pn-orders-db**. Every one of these paths is failing.

In this scenario, you will restore outbound internet access for the private instance, fix its IAM permissions to Amazon S3, repair the security group path to Amazon RDS, and prove the fix end to end with the PAYNOTIFY health check report.

## Scenario

_**Incident Manager:** The web tier is serving again, but no payment notifications have gone out since last night. The app tier health check is red on every line._

_**You (Cloud Engineer):** The app instance does not even show up in Session Manager. I will restore its network path first, then work through S3 and the database._

## Resources Used in This Scenario

| Resource | Name |
|---|---|
| App instance | pn-app-01-<inject key="CloudLabsDeploymentID" /> |
| App subnet | pn-app-subnet-<inject key="CloudLabsDeploymentID" /> |
| Private route table | pn-private-rt-<inject key="CloudLabsDeploymentID" /> |
| NAT gateway | pn-nat-<inject key="CloudLabsDeploymentID" /> |
| App security group | pn-app-sg-<inject key="CloudLabsDeploymentID" /> |
| Database security group | pn-db-sg-<inject key="CloudLabsDeploymentID" /> |
| Orders database | pn-orders-db-<inject key="CloudLabsDeploymentID" /> |
| App data bucket | <inject key="AppDataBucket" /> |

## Task 1: Restore Outbound Internet for the Private App Instance

In this task, you will find out why the private instance has no internet access and cannot register with Systems Manager.

1. In the **EC2** console, select **Instances (1)** and select **pn-app-01-<inject key="CloudLabsDeploymentID" /> (2)**. Notice that the instance has no **Public IPv4 address (3)**.

   ![](../media/s2-t1-01.png)

1. Select **Connect (1)** and open the **Session Manager (2)** tab. The SSM Agent is not online **(3)**, even though the instance role already includes **AmazonSSMManagedInstanceCore**. The agent needs outbound HTTPS to the Systems Manager endpoints.

   ![](../media/s2-t1-02.png)

1. On the instance **Networking (1)** tab, select the subnet **pn-app-subnet-<inject key="CloudLabsDeploymentID" /> (2)**.

   ![](../media/s2-t1-03.png)

1. On the subnet page, open the **Route table (1)** tab. The default route **0.0.0.0/0** points to an internet gateway **igw-xxxx (2)**. An internet gateway only works for instances with a public IP address, so a private instance sending traffic to it gets no response.

   ![](../media/s2-t1-04.png)

1. In the **VPC** console, select **NAT gateways (1)**. Confirm that **pn-nat-<inject key="CloudLabsDeploymentID" />** is **Available (2)** and sits in **pn-public-subnet-a-<inject key="CloudLabsDeploymentID" /> (3)**. The NAT gateway exists but nothing routes to it.

   ![](../media/s2-t1-05.png)

1. Select **Route tables (1)**, select **pn-private-rt-<inject key="CloudLabsDeploymentID" /> (2)**, open the **Routes (3)** tab and select **Edit routes (4)**.

   ![](../media/s2-t1-06.png)

1. For the destination **0.0.0.0/0**, change **Target** to **NAT Gateway (1)** and select **pn-nat-<inject key="CloudLabsDeploymentID" /> (2)**. Select **Save changes (3)**.

   ![](../media/s2-t1-07.png)

1. Return to the **EC2 Instances** page and reboot **pn-app-01-<inject key="CloudLabsDeploymentID" />** by selecting **Instance state (1)**, **Reboot instance (2)** and **Reboot (3)**.

   ![](../media/s2-t1-08.png)

   > **Note:** Wait 3 to 5 minutes for the SSM Agent to register through the NAT gateway.

1. In **Systems Manager**, open **Fleet Manager (1)** and confirm that **pn-app-01-<inject key="CloudLabsDeploymentID" />** shows **Online (2)**.

   ![](../media/s2-t1-09.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S2-T1-VALIDATION-ID" />

## Task 2: Fix EC2-to-S3 Access Using the IAM Role

In this task, you will find and fix the IAM policy errors that stop the app instance from using its S3 bucket.

1. Connect to **pn-app-01-<inject key="CloudLabsDeploymentID" />** using **Session Manager**, then run the PAYNOTIFY health check.

   ```
   sudo /opt/paynotify/healthcheck.sh
   ```

   **INTERNET** now passes, but **S3_LIST**, **S3_WRITE** and **S3_READ** fail with **AccessDenied**, **RDS_TCP** fails, and the report upload fails.

   ![](../media/s2-t2-01.png)

1. In the **EC2** console, open the instance **Security (1)** tab for **pn-app-01** and select the role under **IAM Role (2)**.

   ![](../media/s2-t2-02.png)

1. In **Permissions policies**, expand the inline policy **pn-app-s3-access (1)** and review the JSON **(2)**. Three problems stand out:

   - **s3:ListBucket** is granted on the object ARN **bucket/\***. It is a bucket-level action and must use the bucket ARN.
   - **s3:GetObject** is granted on the bucket ARN. It is an object-level action and must use **bucket/\***.
   - There is no **s3:PutObject** permission at all.

   ![](../media/s2-t2-03.png)

1. Select **Edit (1)**, switch to the **JSON (2)** editor, and replace the content with the policy below. The bucket name **<inject key="AppDataBucket" />** is already filled in.

   ```
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "ListAppDataBucket",
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::<inject key="AppDataBucket" />"
       },
       {
         "Sid": "ReadWriteAppObjects",
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject"
         ],
         "Resource": "arn:aws:s3:::<inject key="AppDataBucket" />/*"
       }
     ]
   }
   ```

   Select **Next (3)** and then **Save changes (4)**.

   ![](../media/s2-t2-04.png)

1. Back on the role page, notice a second, customer managed policy attached to the role **(1)**. Select it and review its JSON **(2)**. It contains an explicit **Deny** for **s3:PutObject** on **reports/\***, left over from change freeze CHG-4471. An explicit Deny always overrides an Allow, so the health report can never be uploaded while it is attached.

   ![](../media/s2-t2-05.png)

1. Return to the role, select the checkbox next to that customer managed policy **(1)**, select **Remove (2)** and confirm **Delete (3)**. This detaches the policy from the role only.

   ![](../media/s2-t2-06.png)

1. Return to the Session Manager session and run the health check again.

   ```
   sudo /opt/paynotify/healthcheck.sh
   ```

   **INTERNET**, **S3_LIST**, **S3_WRITE** and **S3_READ** now pass and the report is uploaded. **RDS_TCP** still fails, which you will fix in the next task.

   ![](../media/s2-t2-07.png)

   > **Note:** IAM changes can take up to one minute to apply. If S3 still fails, wait and run the command again.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S2-T2-VALIDATION-ID" />

## Task 3: Fix EC2-to-RDS Connectivity

In this task, you will trace the connection path from the app instance to the orders database and fix it.

1. Search for **RDS** in the console search bar and open it. Select **Databases (1)** and select **pn-orders-db-<inject key="CloudLabsDeploymentID" /> (2)**.

   ![](../media/s2-t3-01.png)

1. On the **Connectivity & security (1)** tab, note the **Endpoint (2)**, the port **3306 (3)** and the VPC security group **pn-db-sg-<inject key="CloudLabsDeploymentID" /> (4)**. Select the security group.

   ![](../media/s2-t3-02.png)

1. On the **Inbound rules (1)** tab, the only rule allows MySQL 3306 from **pn-web-sg (2)**. The web tier should never talk to the database directly, and the app tier, which does need it, is not allowed.

   ![](../media/s2-t3-03.png)

1. Select **Edit inbound rules (1)**. Delete the rule that references **pn-web-sg (2)**, then select **Add rule (3)** with the following values:

   - **Type:** MYSQL/Aurora **(4)**
   - **Source:** Custom, then select **pn-app-sg-<inject key="CloudLabsDeploymentID" /> (5)**
   - **Description:** MySQL from pn-app tier **(6)**

   Select **Save rules (7)**.

   ![](../media/s2-t3-04.png)

1. In the **EC2** console, select **Security Groups (1)** and select **pn-app-sg-<inject key="CloudLabsDeploymentID" /> (2)**. Open the **Outbound rules (3)** tab. The group only allows **HTTPS 443 (4)** outbound. Security groups are stateful, but the connection still has to be allowed on the side that starts it, so the app instance cannot open TCP 3306.

   ![](../media/s2-t3-05.png)

1. Select **Edit outbound rules (1)**, select **Add rule (2)**, set **Type** to **MYSQL/Aurora (3)**, set **Destination** to **Custom** and select **pn-db-sg-<inject key="CloudLabsDeploymentID" /> (4)**. Select **Save rules (5)**.

   ![](../media/s2-t3-06.png)

1. In the Session Manager session on **pn-app-01**, test the database port directly.

   ```
   DB=<inject key="DatabaseEndpoint" />
   timeout 5 bash -c "exec 3<>/dev/tcp/$DB/3306" && echo "RDS port 3306 is OPEN" || echo "RDS port 3306 is BLOCKED"
   ```

   The output returns **RDS port 3306 is OPEN**.

   ![](../media/s2-t3-07.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S2-T3-VALIDATION-ID" />

## Task 4: Run the End-to-End Health Check

In this task, you will run the PAYNOTIFY health check one final time and confirm that the report in Amazon S3 is fully green.

1. In the Session Manager session on **pn-app-01**, run the health check.

   ```
   sudo /opt/paynotify/healthcheck.sh
   ```

   All five checks, **INTERNET**, **S3_LIST**, **S3_WRITE**, **S3_READ** and **RDS_TCP**, show **PASS**, and the report is uploaded.

   ![](../media/s2-t4-01.png)

1. Search for **S3** in the console search bar and open it. Select the bucket **<inject key="AppDataBucket" /> (1)** and open the **reports/ (2)** folder.

   ![](../media/s2-t4-02.png)

1. Select **healthcheck-latest.txt (1)** and select **Open (2)**. Confirm that every line shows **PASS** and that **INSTANCE** matches the instance ID of **pn-app-01 (3)**.

   ![](../media/s2-t4-03.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S2-T4-VALIDATION-ID" />

## Summary

In this scenario, you:

- Replaced a private default route that pointed to the internet gateway with a route to the NAT gateway.
- Corrected swapped S3 resource ARNs and added the missing write permission to the instance role.
- Removed a stale explicit Deny that blocked report uploads.
- Moved database access from the web tier to the app tier and allowed outbound MySQL from the app tier.
- Proved the full path with the PAYNOTIFY health check report in Amazon S3.

Click the **Next** button to begin Scenario 3.

### Happy Assessing !!
