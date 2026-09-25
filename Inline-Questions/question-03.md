## MetaData
Question Type : Single Choice

## Question
3. Finance flagged high NAT gateway data processing charges caused by the app tier downloading statement files from Amazon S3 in the same Region. Which change removes those charges while keeping the instances private?

## Options
Option 1 : Give the app instances public IP addresses so S3 downloads leave through igw-0main instead.

Option 2 : Replace nat-0a1 with a NAT instance on a larger instance type to cut the per-GB charges.

Option 3 : Create an S3 gateway endpoint associated with rt-app so S3 traffic stops using nat-0a1.

Option 4 : Create an S3 interface endpoint in public-a and point the rt-app 0.0.0.0/0 route at it.

## Answers
Option 3 : 2

## Number of Retries
1
