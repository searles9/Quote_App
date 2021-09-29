import sys
import logging
import traceback
import json
import random
import boto3
from boto3.dynamodb.conditions import Key, Attr

# Setup logging stuff
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get the service resource
dynamodb = boto3.resource('dynamodb')
# Instantiate a table resource object
table = dynamodb.Table('MyTable')

def getItem():
    response = table.get_item(
        Key={
            'id': 7,
            'quotetype': 'general'
        }
    )
    item = response['Item']
    return item

def queryItem(idnum):
    response = table.query(
        KeyConditionExpression=Key('id').eq(idnum)
    )
    items = response['Items']
    logger.info(f"The return from the query: {items}")
    for item in items:
            logger.info(item['quote'])
            theitem = item['quote']
    return str(theitem)

def lambda_handler(event, context): 
    try:
        logger.info(f'event: {event}')
        
        quote = queryItem(random.choice(range(1,11)))

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