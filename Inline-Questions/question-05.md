## MetaData
Question Type : Multiple Choice

## Question
5. Users report that roughly half of the requests to the internet-facing load balancer pn-alb-reporting time out, while the rest succeed. Which two statements are correct? Select two.

## Options
Option 1 : Cross-zone load balancing is disabled, so the node in public-b drops half of all the requests.

Option 2 : Clients sent to the load balancer node in public-b time out as rt-public-b has no IGW route.

Option 3 : The targets in app-b need public IP addresses so the node in public-b is able to reach them.

Option 4 : Adding a 0.0.0.0/0 route to igw-0main in rt-public-b makes both balancer nodes reachable.

## Answers
Option 2 : 2
Option 4 : 2

## Number of Retries
1
