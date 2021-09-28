import json

print('Loading MyFunc')

def lambda_handler(event, context): 
    print("testing")
    message = {
       'message': 'It Worked!'
    }
    apiResponse = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(message)
    }
    return apiResponse