## MetaData
Question Type : Single Choice

## Question
4. The monitoring server in vpc-shared uses security group sg-0mon and must scrape port 9100 on the core app instances. How should the core app security group allow this traffic?

## Options
Option 1 : It is not possible, because a security group can only reference groups inside its own VPC.

Option 2 : Add an outbound rule on 9100 to sg-0mon, because the monitoring server starts each flow.

Option 3 : Add an inbound rule on 9100 from 0.0.0.0/0, since peered traffic ignores group references.

Option 4 : Add an inbound rule on 9100 that references sg-0mon, as the peering is in one Region.

## Answers
Option 4 : 2

## Number of Retries
1
