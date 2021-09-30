import sys
import logging
import traceback
import json
import random
import boto3

# Setup logging stuff
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get the service resource
dynamodb = boto3.resource('dynamodb')
# Instantiate a table resource object
table = dynamodb.Table('MyTable')


def getItem(idnum,rangekey):
    response = table.get_item(
        Key={
            'id': idnum,
            'quotetype': rangekey
        }
    )
    logger.info(f"full get_item result: {response['Item']}")
    return response['Item']['quote']

def lambda_handler(event, context): 
    try:
        logger.info(f'event: {event}')
        quote = getItem(random.choice(range(1,11)),'general')
        message = {
                'message': quote
        }
        apiResponse = {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps(message)
        }
        return apiResponse
      
    except Exception as exp:
        exception_type, exception_value, exception_traceback = sys.exc_info()
        traceback_string = traceback.format_exception(exception_type, exception_value, exception_traceback)
        err_msg = json.dumps({
            "errorType": exception_type.__name__,
            "errorMessage": str(exception_value),
            "stackTrace": traceback_string
        })
        logger.error(err_msg)