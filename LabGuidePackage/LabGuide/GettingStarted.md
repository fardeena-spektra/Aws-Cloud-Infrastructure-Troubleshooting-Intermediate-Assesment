# AWS Cloud Infrastructure Troubleshooting (Intermediate) Assessment

## Overview

Welcome to the **AWS Cloud Infrastructure Troubleshooting (Intermediate)** assessment.

Nedbank runs **PAYNOTIFY**, a payment notification service, on AWS. After last night's change window the service is down. Customers get an error from the public load balancer, the operations team cannot open a session on the web instance, and the private application tier can no longer reach the internet, Amazon S3 or the orders database.

In this assessment you take the role of the on-call cloud engineer. You will diagnose and repair a deliberately broken AWS environment across the web tier and the private application tier, and then answer scenario-based networking questions about a wider PAYNOTIFY design.

## Objectives

In this assessment, you will:

- Troubleshoot EC2 connectivity and restore Session Manager access
- Repair an Application Load Balancer, its listener, target group and security groups
- Troubleshoot network ACL and security group rules that block traffic between tiers
- Restore internet connectivity for a private EC2 instance
- Fix EC2-to-S3 access using IAM roles
- Troubleshoot EC2-to-RDS connectivity
- Analyse an AWS network design and identify routing, peering and endpoint issues

## Prerequisites

Participants should have working knowledge of the following:

- Amazon VPC, subnets, route tables, internet gateways and NAT gateways
- Security groups and network ACLs
- IAM roles, instance profiles and IAM policy evaluation
- Application Load Balancer listeners and target groups
- AWS Systems Manager Session Manager
- Basic Linux shell commands

## Architecture

![](../media/architecture.png)

- **pn-alb** is an internet-facing Application Load Balancer in two public subnets. It forwards HTTP traffic to **pn-web-01** on port 8080 through the target group **pn-web-tg**.
- **pn-web-01** runs the PAYNOTIFY web front end in its own subnet, **pn-web-subnet**, protected by **pn-web-sg** and **pn-web-nacl**.
- **pn-app-01** is a private instance in **pn-app-subnet**. It reaches the internet through the NAT gateway **pn-nat**, writes to the S3 bucket **pn-appdata**, and connects to the MySQL database **pn-orders-db**.
- Every instance is managed through AWS Systems Manager Session Manager. No SSH keys are used.

## Scenario Breakdown

| Scenario | Title | Type | Tasks |
|---|---|---|---|
| Scenario 1 | Restore the PAYNOTIFY Web Tier | Hands-on | 4 validated tasks |
| Scenario 2 | Repair the Private Application Tier | Hands-on | 4 validated tasks |
| Scenario 3 | Diagnose the PAYNOTIFY Network Design | Questions | 6 questions |

## Scoring Summary

- Scenario 1 and Scenario 2 are scored by the **Validate** button at the end of each task.
- Scenario 3 contains single choice and multiple choice questions. Each correct answer carries **2 marks**.
- Each question allows **1** retry.

## Environment Details

| Item | Value |
|---|---|
| AWS Region | <inject key="Region" enableCopy="true"/> |
| Deployment ID | <inject key="CloudLabsDeploymentID" enableCopy="true"/> |
| Load balancer DNS name | <inject key="LoadBalancerDNS" enableCopy="true"/> |
| App data bucket | <inject key="AppDataBucket" enableCopy="true"/> |
| Orders database endpoint | <inject key="DatabaseEndpoint" enableCopy="true"/> |

All resources in this assessment carry the suffix **-<inject key="CloudLabsDeploymentID" />** in their names, for example **pn-web-01-<inject key="CloudLabsDeploymentID" />**.

## Accessing Your Assessment Environment

Once you are ready to begin, your virtual machine and **Guide** are available within your web browser.

![](../media/gs-01.png)

## Virtual Machine and Assessment Guide

Your Windows virtual machine is your workstation throughout this assessment. If you are asked to sign in to the virtual machine, use the following credentials:

- **Username:** <inject key="VMUserName" enableCopy="true"/>
- **Password:** <inject key="VMPassword" enableCopy="true"/>

## Exploring Your Assessment Resources

To view your AWS console credentials and resource details, navigate to the **Environment** tab.

![](../media/gs-02.png)

## Signing in to the AWS Management Console

1. On the virtual machine, open **Microsoft Edge**.

1. Navigate to the AWS console sign-in URL shown on the **Environment** tab.

1. Sign in with the **AWS username (1)** and **AWS password (2)** shown on the **Environment** tab, then select **Sign in (3)**.

   ![](../media/gs-03.png)

1. In the top-right corner of the console, confirm that the Region is set to **<inject key="Region" />**.

   ![](../media/gs-04.png)

   > **Note:** All assessment resources are deployed in this Region. If you do not see a resource, check the Region selector first.

## Utilizing the Split Window Feature

For convenience, you can open the assessment guide in a separate window by selecting the **Split Window** button from the top-right corner.

![](../media/gs-05.png)

## Managing Your Virtual Machine

You can start, stop or restart your virtual machine as needed from the **Resources** tab.

![](../media/gs-06.png)

## Support Contact

The **CloudLabs support team** is available 24/7, 365 days a year, via email and live chat. We offer dedicated support channels for both learners and instructors.

Learner Support Contacts:

- Email Support: cloudlabs-support@spektrasystems.com

- Live Chat Support: https://cloudlabs.ai/labs-support

Now, click **Next** from the lower-right corner to begin Scenario 1.

![](../media/gs-next.png)

### Happy Assessing !!
