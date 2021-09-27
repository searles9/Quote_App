# Func
import json

def lambda_handler(event, context):
    #message = 'Hello {}!'.format(event['first_name'])  
    print("testing")
    message = "It worked!"
    apiResponse = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "message": message
    }
    return apiResponse