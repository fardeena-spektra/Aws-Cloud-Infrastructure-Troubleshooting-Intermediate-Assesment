# Scenario 1: Restore the PAYNOTIFY Web Tier

### Duration: 60 Minutes

## Overview

During last night's change window, the PAYNOTIFY web tier was moved behind a new Application Load Balancer. Since then, customers opening the service receive an error page, and the operations team cannot open a Session Manager session on the web instance to investigate.

In this scenario, you will restore management access to the web instance, fix the service listener on the host, correct the security group and network ACL rules between the load balancer and the web tier, and repair the load balancer configuration until PAYNOTIFY serves traffic again.

## Scenario

_**Incident Manager:** PAYNOTIFY is returning errors to every customer since the change window. We need the web tier back as a priority._

_**You (Cloud Engineer):** I can see the load balancer is up, but Session Manager does not even list the web instance. I will start with management access and work outwards to the load balancer._

## Resources Used in This Scenario

| Resource | Name |
|---|---|
| Web instance | pn-web-01-<inject key="CloudLabsDeploymentID" /> |
| Web subnet | pn-web-subnet-<inject key="CloudLabsDeploymentID" /> |
| Web security group | pn-web-sg-<inject key="CloudLabsDeploymentID" /> |
| Web network ACL | pn-web-nacl-<inject key="CloudLabsDeploymentID" /> |
| Load balancer | pn-alb-<inject key="CloudLabsDeploymentID" /> |
| Load balancer security group | pn-alb-sg-<inject key="CloudLabsDeploymentID" /> |
| Target group | pn-web-tg-<inject key="CloudLabsDeploymentID" /> |

## Task 1: Restore Session Manager Connectivity to the Web Instance

In this task, you will find out why the web instance cannot be managed through Session Manager and restore that access.

1. In the AWS Management Console, search for **EC2 (1)** in the search bar and select **EC2 (2)**.

   ![](../media/s1-t1-01.png)

1. From the left navigation pane, select **Instances (1)**, then select the instance **pn-web-01-<inject key="CloudLabsDeploymentID" /> (2)**.

   ![](../media/s1-t1-02.png)

1. Select **Connect (1)**, then open the **Session Manager (2)** tab. Notice that the **Connect** button is unavailable and the console reports that the SSM Agent is not online **(3)**.

   ![](../media/s1-t1-03.png)

1. Return to the instance details, open the **Security (1)** tab and select the role name shown under **IAM Role (2)**.

   ![](../media/s1-t1-04.png)

1. On the role page, review the **Permissions policies (1)** list. The role only has **CloudWatchAgentServerPolicy (2)**, which does not allow the SSM Agent to register the instance with Systems Manager.

   ![](../media/s1-t1-05.png)

1. Select **Add permissions (1)**, then select **Attach policies (2)**.

   ![](../media/s1-t1-06.png)

1. Search for **AmazonSSMManagedInstanceCore (1)**, select the checkbox next to it **(2)** and select **Add permissions (3)**.

   ![](../media/s1-t1-07.png)

1. Return to the **EC2 Instances** page, select **pn-web-01-<inject key="CloudLabsDeploymentID" /> (1)**, then select **Instance state (2)** and **Reboot instance (3)**. Confirm with **Reboot (4)**.

   ![](../media/s1-t1-08.png)

   > **Note:** The reboot makes the SSM Agent register again with the new role permissions. Wait 3 to 5 minutes before continuing.

1. Search for **Systems Manager** in the console search bar and open it. From the left navigation pane, select **Fleet Manager (1)** and confirm that **pn-web-01-<inject key="CloudLabsDeploymentID" />** shows the SSM Agent ping status **Online (2)**.

   ![](../media/s1-t1-09.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S1-T1-VALIDATION-ID" />

## Task 2: Fix the Web Service Listener on the Instance

In this task, you will connect to the web instance and find out why the web service cannot be reached from other hosts.

1. On the **EC2 Instances** page, select **pn-web-01-<inject key="CloudLabsDeploymentID" /> (1)**, select **Connect (2)**, open the **Session Manager (3)** tab and select **Connect (4)**.

   ![](../media/s1-t2-01.png)

1. In the session window, check the status of the PAYNOTIFY web service by running the command below. The service is **active (running)**.

   ```
   sudo systemctl status paynotify-web --no-pager
   ```

   ![](../media/s1-t2-02.png)

1. Check which address the service is listening on.

   ```
   sudo ss -lntp | grep 8080
   ```

   The output shows **127.0.0.1:8080**. The service only accepts connections from the instance itself, so the load balancer can never reach it.

   ![](../media/s1-t2-03.png)

1. Review the service definition to find where the bind address is set.

   ```
   sudo systemctl cat paynotify-web
   ```

   ![](../media/s1-t2-04.png)

1. Change the bind address to listen on all interfaces, then reload systemd and restart the service.

   ```
   sudo sed -i 's/--bind 127.0.0.1/--bind 0.0.0.0/' /etc/systemd/system/paynotify-web.service
   sudo systemctl daemon-reload
   sudo systemctl restart paynotify-web
   ```

   ![](../media/s1-t2-05.png)

1. Confirm that the service now listens on **0.0.0.0:8080** and that the health page responds on the private IP address of the instance.

   ```
   sudo ss -lntp | grep 8080
   IP=$(hostname -I | cut -d" " -f1); curl -s -w "\nHTTP %{http_code}\n" http://$IP:8080/health
   ```

   The output returns **OK** and **HTTP 200**.

   ![](../media/s1-t2-06.png)

1. Keep the session open, you may need it later in this scenario.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S1-T2-VALIDATION-ID" />

## Task 3: Fix the Web Tier Security Group and Network ACL

In this task, you will correct the traffic rules between the load balancer and the web tier.

1. In the **EC2** console, from the left navigation pane, select **Security Groups (1)** and select **pn-web-sg-<inject key="CloudLabsDeploymentID" /> (2)**.

   ![](../media/s1-t3-01.png)

1. Open the **Inbound rules (1)** tab. The only rule allows TCP 8080 from **10.99.0.0/16 (2)**, a legacy range that is not used in this VPC. The new load balancer can never match this rule.

   ![](../media/s1-t3-02.png)

1. Select **Edit inbound rules (1)**. Delete the rule for **10.99.0.0/16 (2)**, then select **Add rule (3)** and configure it as follows:

   - **Type:** Custom TCP **(4)**
   - **Port range:** 8080 **(5)**
   - **Source:** Custom, then select the security group **pn-alb-sg-<inject key="CloudLabsDeploymentID" /> (6)**
   - **Description:** App traffic from pn-alb **(7)**

   Select **Save rules (8)**.

   ![](../media/s1-t3-03.png)

   > **Note:** Referencing the load balancer security group, rather than a CIDR range, keeps the rule correct even when the load balancer nodes change IP addresses.

1. Search for **VPC** in the console search bar and open it. From the left navigation pane, select **Network ACLs (1)** and select **pn-web-nacl-<inject key="CloudLabsDeploymentID" /> (2)**.

   ![](../media/s1-t3-04.png)

1. Open the **Inbound rules (1)** tab. Rule **100** allows all traffic, so the requests from the load balancer are accepted.

   ![](../media/s1-t3-05.png)

1. Open the **Outbound rules (1)** tab. Rule **90 (2)** denies TCP **1024-65535** to **10.10.0.0/16**. Network ACLs are stateless, so the web instance replies to the load balancer node on the node's ephemeral port. Rule 90 is evaluated before rule 100 and drops every reply, including the health check responses.

   ![](../media/s1-t3-06.png)

1. Select **Edit outbound rules (1)**, select **Remove (2)** next to rule **90**, and select **Save changes (3)**.

   ![](../media/s1-t3-07.png)

1. Confirm that the outbound rules now contain only rule **100 (Allow all)** and the default **\* (Deny)** rule.

   ![](../media/s1-t3-08.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S1-T3-VALIDATION-ID" />

## Task 4: Repair the Application Load Balancer

In this task, you will fix the target group health check, the load balancer security group and the listener so that customer traffic reaches the web tier.

1. Return to the **EC2** console. From the left navigation pane, under **Load Balancing**, select **Target Groups (1)** and select **pn-web-tg-<inject key="CloudLabsDeploymentID" /> (2)**.

   ![](../media/s1-t4-01.png)

1. Open the **Targets (1)** tab. The target **pn-web-01** is **Unhealthy (2)**. Hover over the status to see the reason: health checks fail with code **404 (3)**.

   ![](../media/s1-t4-02.png)

1. Open the **Health checks (1)** tab. The health check path is **/healthz (2)**, but the PAYNOTIFY web service only exposes **/health**. Select **Edit (3)**.

   ![](../media/s1-t4-03.png)

1. Change **Health check path** to **/health (1)** and select **Save changes (2)**.

   ![](../media/s1-t4-04.png)

1. From the left navigation pane, select **Load Balancers (1)** and select **pn-alb-<inject key="CloudLabsDeploymentID" /> (2)**. Open the **Security (3)** tab and select the security group **pn-alb-sg-<inject key="CloudLabsDeploymentID" /> (4)**.

   ![](../media/s1-t4-05.png)

1. On the **Inbound rules (1)** tab, notice that only **HTTPS 443 (2)** is allowed. The load balancer listener runs on **HTTP 80**, so customer requests are dropped before they reach the listener. Select **Edit inbound rules (3)**.

   ![](../media/s1-t4-06.png)

1. Select **Add rule (1)**, set **Type** to **HTTP (2)**, set **Source** to **Anywhere-IPv4 (3)**, and select **Save rules (4)**.

   ![](../media/s1-t4-07.png)

1. Return to **pn-alb-<inject key="CloudLabsDeploymentID" />** and open the **Listeners and rules (1)** tab. The **HTTP:80** listener has a default action of **Return fixed response 503 (2)**. This is a maintenance response left over from the change window.

   ![](../media/s1-t4-08.png)

1. Select the **HTTP:80 (1)** listener, select **Manage listener (2)**, then select **Edit listener (3)**.

   ![](../media/s1-t4-09.png)

1. Under **Default actions**, select **Forward to target groups (1)**, choose **pn-web-tg-<inject key="CloudLabsDeploymentID" /> (2)**, and select **Save changes (3)**.

   ![](../media/s1-t4-10.png)

1. Return to the target group **pn-web-tg-<inject key="CloudLabsDeploymentID" />** and confirm that **pn-web-01** now shows **Healthy (1)**. It can take up to one minute.

   ![](../media/s1-t4-11.png)

1. In a new browser tab on the virtual machine, open the load balancer DNS name below. The **PAYNOTIFY Payment Notification Service** page is displayed.

   ```
   http://<inject key="LoadBalancerDNS" />
   ```

   ![](../media/s1-t4-12.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the assessment guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="REPLACE-WITH-S1-T4-VALIDATION-ID" />

## Summary

In this scenario, you:

- Restored Session Manager access by granting the web instance role the Systems Manager permissions.
- Fixed a web service that only listened on the loopback address.
- Replaced a stale security group rule with a reference to the load balancer security group.
- Removed a network ACL rule that dropped return traffic to ephemeral ports.
- Corrected the health check path, the load balancer security group and the listener default action.

Click the **Next** button to begin Scenario 2.

### Happy Assessing !!
