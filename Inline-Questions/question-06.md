## MetaData
Question Type : Single Choice

## Question
6. The target group behind pn-dev-alb shows dev-web as Unhealthy with health checks failing on code 404. The site works on the instance. What is the most likely cause?

## Options
Option 1 : The health check path points to a page that does not exist on the web application.

Option 2 : The load balancer is internal, so its health checks cannot reach any public instance.

Option 3 : dev-web has too little memory, so it returns 404 whenever the load balancer checks it.

Option 4 : The target group uses HTTP, and health checks only work when the protocol is HTTPS.

## Answers
Option 1 : 2

## Number of Retries
1
