# Scenario 3: Review the PAYNOTIFY Network Basics

### Duration: 20 Minutes

## Overview

The PAYNOTIFY team is building a development copy of the service in a separate VPC. Before the build goes live, the team lead asks you to review the design below and answer a few questions about how traffic and access work in it.

**VPC pn-dev-vpc, CIDR 10.20.0.0/16:**

| Subnet | CIDR | Route table entries |
|---|---|---|
| dev-public | 10.20.1.0/24 | 10.20.0.0/16 to local, 0.0.0.0/0 to igw-dev |
| dev-private | 10.20.2.0/24 | 10.20.0.0/16 to local, 0.0.0.0/0 to nat-dev |

**Resources:**

| Resource | Placement | Details |
|---|---|---|
| igw-dev | pn-dev-vpc | Internet gateway |
| nat-dev | dev-public | NAT gateway |
| pn-dev-alb | dev-public | Internet-facing Application Load Balancer, target group with dev-web |
| dev-web | dev-public | EC2 web server with a public IP, security group sg-dev-web |
| dev-app | dev-private | EC2 app server, no public IP, security group sg-dev-app, IAM role dev-app-role |
| dev-db | dev-private | Amazon RDS for MySQL on port 3306, security group sg-dev-db |
| dev-reports | Amazon S3 | Bucket used by dev-app |

**Security group inbound rules:**

| Security group | Port | Source |
|---|---|---|
| sg-dev-web | 80 | 0.0.0.0/0 |
| sg-dev-app | 8080 | sg-dev-web |
| sg-dev-db | 3306 | sg-dev-app |

All security groups keep the default outbound rule that allows all traffic.

**IAM role dev-app-role:** allows **s3:GetObject** on **arn:aws:s3:::dev-reports/\***.

**Reference notes** - background you may need. These are not clues specific to this incident.

- A **public subnet** has a route to an internet gateway. A **private subnet** does not, and usually reaches the internet through a **NAT gateway** placed in a public subnet.
- **Security groups** are stateful. Return traffic for an allowed connection is allowed automatically.
- EC2 instances should get AWS permissions through an **IAM role**, not stored access keys.

## Answer the following questions

<question source="../../Inline-Questions/question-01.md" />

<br>

<question source="../../Inline-Questions/question-02.md" />

<br>

<question source="../../Inline-Questions/question-03.md" />

<br>

<question source="../../Inline-Questions/question-04.md" />

<br>

<question source="../../Inline-Questions/question-05.md" />

<br>

<question source="../../Inline-Questions/question-06.md" />

## Summary

In this scenario, you reviewed public and private subnets, NAT gateway traffic, security group rules, IAM role permissions for S3 and load balancer health checks.

You have completed the assessment. Select **End** to submit your results.

### Happy Assessing !!
