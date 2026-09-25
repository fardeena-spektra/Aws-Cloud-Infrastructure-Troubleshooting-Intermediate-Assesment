## MetaData
Question Type : Single Choice

## Question
2. dev-app has no public IP address but must download software updates from the internet. How does its traffic leave the VPC?

## Options
Option 1 : It goes to the internet gateway directly, as dev-private has a local route to igw-dev.

Option 2 : It cannot leave the VPC, because instances without a public IP never reach the internet.

Option 3 : It goes through dev-web, which forwards the requests since both sit inside pn-dev-vpc.

Option 4 : It goes to nat-dev in dev-public, which then sends the traffic out through igw-dev.

## Answers
Option 4 : 2

## Number of Retries
1
