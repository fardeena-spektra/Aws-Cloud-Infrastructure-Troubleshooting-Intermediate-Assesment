## MetaData
Question Type : Single Choice

## Question
1. Read the flow log excerpt for eni-0db01. The inbound packet from the app instance to port 3306 is accepted, but the reply packet is rejected. What is the most likely cause of the database connection timeouts?

## Options
Option 1 : The database security group is missing an outbound rule that allows replies on port 3306.

Option 2 : acl-db outbound only allows port 3306, so replies to client ephemeral ports are dropped.

Option 3 : rt-db has no route back to 10.10.11.0/24, so the database replies cannot find the client.

Option 4 : The database listens on a non-default port, so the reply is rejected by the database host.

## Answers
Option 2 : 2

## Number of Retries
1
