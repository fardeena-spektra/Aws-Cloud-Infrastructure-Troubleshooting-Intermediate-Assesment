# Scenario 3: Diagnose the PAYNOTIFY Network Design

### Duration: 30 Minutes

## Overview

With the production incident closed, the architecture board asks you to review the wider PAYNOTIFY network in the **vpc-core** account before the next release. The design has grown over several projects and a number of connectivity complaints are still open. Below are the VPC layout, the route tables, a network ACL, a flow log excerpt and the open complaints collected by the operations team.

**VPCs and peering, all in the same AWS Region:**

| VPC | CIDR | Purpose |
|---|---|---|
| vpc-core | 10.10.0.0/16 | PAYNOTIFY production workloads |
| vpc-shared | 10.30.0.0/16 | Shared services, monitoring server with security group sg-0mon |
| vpc-analytics | 10.10.128.0/17 | Reporting and dashboards |

| Peering connection | Between | Status |
|---|---|---|
| pcx-core-shared | vpc-core and vpc-shared | Active |
| pcx-shared-analytics | vpc-shared and vpc-analytics | Active |

**Subnets in vpc-core:**

| Subnet | CIDR | Availability Zone | Route table | Notes |
|---|---|---|---|---|
| public-a | 10.10.1.0/24 | AZ a | rt-public-a | Load balancer node |
| public-b | 10.10.2.0/24 | AZ b | rt-public-b | Load balancer node |
| app-a | 10.10.11.0/24 | AZ a | rt-app | App instances, no public IPs |
| app-b | 10.10.12.0/24 | AZ b | rt-app-b | Hosts NAT gateway nat-0a1 |
| db-a | 10.10.21.0/24 | AZ a | rt-db | Database, network ACL acl-db |

**Route tables in vpc-core:**

| Route table | Destination | Target |
|---|---|---|
| rt-public-a | 10.10.0.0/16 | local |
| rt-public-a | 0.0.0.0/0 | igw-0main |
| rt-public-b | 10.10.0.0/16 | local |
| rt-public-b | 10.30.0.0/16 | pcx-core-shared |
| rt-app | 10.10.0.0/16 | local |
| rt-app | 0.0.0.0/0 | nat-0a1 |
| rt-app | 10.30.0.0/16 | pcx-core-shared |
| rt-app-b | 10.10.0.0/16 | local |
| rt-app-b | 0.0.0.0/0 | nat-0a1 |
| rt-db | 10.10.0.0/16 | local |

**Network ACL acl-db, associated with db-a:**

| Direction | Rule | Protocol | Port | Source or destination | Action |
|---|---|---|---|---|---|
| Inbound | 100 | TCP | 3306 | 10.10.11.0/24 | Allow |
| Inbound | * | All | All | 0.0.0.0/0 | Deny |
| Outbound | 100 | TCP | 3306 | 10.10.11.0/24 | Allow |
| Outbound | * | All | All | 0.0.0.0/0 | Deny |

**VPC flow log excerpt for the database network interface eni-0db01:**

```
srcaddr       dstaddr       srcport  dstport  protocol  action
10.10.11.25   10.10.21.40   51544    3306     6         ACCEPT
10.10.21.40   10.10.11.25   3306     51544    6         REJECT
```

**Open complaints:**

- App instances in app-a time out when they connect to the database in db-a.
- App instances in app-a cannot download operating system updates from the internet. nat-0a1 shows the state **Available**.
- Roughly half of the requests to the internet-facing load balancer **pn-alb-reporting**, which uses public-a and public-b, time out.
- Finance flagged high NAT gateway data processing charges. Most of that traffic is statement files downloaded from Amazon S3 in the same Region.
- The analytics team wants direct access from vpc-analytics to the PAYNOTIFY database in vpc-core.
- The monitoring server in vpc-shared must scrape port 9100 on the vpc-core app instances.

**Reference notes** - background you may need. These are not clues specific to this incident.

- **Network ACLs** are stateless and evaluate rules in number order. Return traffic must be allowed explicitly, usually on the ephemeral port range 1024-65535. **Security groups** are stateful.
- A **NAT gateway** needs a route to an internet gateway in its own subnet to forward traffic to the internet.
- **VPC peering** requires non-overlapping CIDR blocks and does not support transitive routing.
- A **gateway endpoint** for Amazon S3 is added as a route in selected route tables and has no data processing charge.

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

In this scenario, you reviewed the PAYNOTIFY network design and identified issues with stateless network ACL rules, NAT gateway placement, load balancer subnet routing, S3 traffic cost, VPC peering limits and cross-VPC security group references.

You have completed the assessment. Select **End** to submit your results.

### Happy Assessing !!
