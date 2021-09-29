import json
import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = "MyTable"
# Create the table resource
dynamodb = boto3.resource('dynamodb', region_name="us-east-1")
table = dynamodb.Table(TABLE_NAME)

def getData():
    response = table.query(
        KeyConditionExpression=Key('id').eq('7'),
        ExpressionAttributeValues={
            ':id': {'N': '7'}
        }
    )
    return response['Items']

def lambda_handler(event, context): 
    message = {
       'message': json.dumps(getData())
    }
    apiResponse = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(message)
    }
    return apiResponse