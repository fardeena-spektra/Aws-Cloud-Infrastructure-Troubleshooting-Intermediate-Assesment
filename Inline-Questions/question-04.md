## MetaData
Question Type : Single Choice

## Question
4. sg-dev-web allows inbound port 80 from 0.0.0.0/0 and still has its default outbound rule. Do the web responses reach the customers?

## Options
Option 1 : No, an outbound rule for port 80 must be added so that the responses can leave dev-web.

Option 2 : Yes, security groups are stateful, so replies to allowed requests are allowed out.

Option 3 : No, the network ACL must first be changed to allow outbound port 80 from dev-public.

Option 4 : Yes, but only when the customers connect using HTTPS on port 443 instead of port 80.

## Answers
Option 2 : 2

## Number of Retries
1
