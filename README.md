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
***
# Notes
* Test invoke the function: aws lambda invoke --region=us-east-1 --function-name=$(terraform output -raw function_name) response.json
* curl: curl "$(terraform output -raw base_api_url)/quote"