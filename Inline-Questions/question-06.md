## MetaData
Question Type : Single Choice

## Question
6. Instances in app-a cannot reach the internet, even though rt-app sends 0.0.0.0/0 to nat-0a1 and the NAT gateway shows Available. What fixes the issue?

## Options
Option 1 : Attach a second internet gateway to vpc-core and add it to rt-app-b next to the NAT route.

Option 2 : Allocate a second Elastic IP to nat-0a1 so it can translate traffic for several subnets.

Option 3 : Recreate the NAT gateway in a public subnet, then point the rt-app default route at it.

Option 4 : Change the rt-app default route from nat-0a1 to igw-0main so that app-a uses the gateway.

## Answers
Option 3 : 2

## Number of Retries
1
