## MetaData
Question Type : Single Choice

## Question
3. A developer on dev-web tries to connect to the dev-db database on port 3306 and the connection times out. Why?

## Options
Option 1 : sg-dev-db only allows 3306 from sg-dev-app, so traffic from dev-web is not allowed.

Option 2 : dev-web sits in a public subnet, and public instances can never connect to RDS databases.

Option 3 : RDS MySQL listens on port 1433, so the developer must connect to that port on dev-db.

Option 4 : dev-db has no public IP address, so no instance in the VPC is able to reach it at all.

## Answers
Option 1 : 2

## Number of Retries
1
