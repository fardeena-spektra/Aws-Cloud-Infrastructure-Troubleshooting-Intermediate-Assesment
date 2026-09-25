## MetaData
Question Type : Single Choice

## Question
1. Which subnet in pn-dev-vpc is a public subnet, and why?

## Options
Option 1 : dev-private, because the NAT gateway in dev-public gives its instances public IP addresses.

Option 2 : dev-public, because its route table sends 0.0.0.0/0 to the internet gateway igw-dev.

Option 3 : Both subnets, because every subnet in a VPC with an internet gateway is public by default.

Option 4 : Neither subnet, because a subnet becomes public only when a load balancer is placed in it.

## Answers
Option 2 : 2

## Number of Retries
1
