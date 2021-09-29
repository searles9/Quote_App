# Quote App / Terraform AWS Deployment
Terraform (IAC) AWS App Deployment

# Important notes
* I could have broken some of the resources into modules - I just didnt want to go through that extra work for this particular project

# What is this?

# How does it work?
* run apply
* change api url
* run the apply again
***
# Documentation / Guides
* I used this guide as a starting point for this project: https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway
* Lambda Handler: https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
* Parsing a JSON object with JS: https://www.freecodecamp.org/news/json-stringify-example-how-to-parse-a-json-object-with-javascript/
* More parsing a JSON object with JS: https://www.tutorialrepublic.com/javascript-tutorial/javascript-json-parsing.php
* Javascript textContent property: https://www.w3schools.com/jsref/prop_node_textcontent.asp
* Javascript addEventListener() method: https://www.w3schools.com/jsref/met_element_addeventlistener.asp
* simple microservice using Lambda and API Gateway: https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway-blueprint.html
* You dont have to define all dynamodb attributes up front: https://newbedev.com/terraform-dynamodb-all-attributes-must-be-indexed
* DynamoDB partition key: https://aws.amazon.com/blogs/database/choosing-the-right-dynamodb-partition-key/
* Using terraform to write bulk items to dynamodb: https://jacob-hudson.github.io/terraform/aws/dynamodb/2020/04/27/terraform-bulk-upload.html
* Query DynamoDB: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.04.html
***
# Notes
* Test invoke the function: aws lambda invoke --region=us-east-1 --function-name=$(terraform output -raw function_name) response.json
* curl: curl "$(terraform output -raw base_api_url)/quote"