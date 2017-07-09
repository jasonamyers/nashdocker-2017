
""" S3 Watcher Lambda

Reacts to Events from a Kinesis stream, and parses s3 file uploads and triggers
pipelines
"""
import base64
import json
import logging

import boto3


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)
DYNAMO = boto3.client('dynamodb')
LAMBDA = boto3.client('lambda')


def get_key_name(event):
    return event['Records'][0]['s3']['object']['key']


def get_key_details(key_name):
    key_parts = key_name.split('/')
    return (key_parts[1], key_parts[2], key_parts[-1])


def handle(event, context):
    """ Receives the event trigger, typically a Kinesis stream event and
    determines if a pipeline is finished. Invokes a telemetry lambda
    if a pipeline is complete.

    :param event: The data from the triggering event
    :type event: dict
    :param context: Any additional context from the event
    :type context: dict

    :return: None
    :rtype: None
    """
    for record in event.get('Records', []):
        payload = json.loads(base64.b64decode(record["kinesis"]["data"]))
        LOGGER.info('Payload: %s', payload)
        key_name = get_key_name(payload)
        app_slug, uuid_folder, file_name = get_key_details(key_name)
        if not app_slug or not file_name:
            return event

        response = DYNAMO.get_item(
                TableName='FilesToPipelines',
                Key={
                    'App': {'S': app_slug},
                    'File': {'S': file_name}
                },
                ProjectionExpression='Pipeline')
        if 'Item' not in response:
            LOGGER.info('Could not file pipeline for %s', key_name)
            return
        if not response['Item'].get('Pipeline'):
            LOGGER.info('Could not file pipeline for %s: Got %s',
                        key_name, response)
            return

        pipeline = response['Item']['Pipeline']["S"]
        response = LAMBDA.invoke_async(
            FunctionName=pipeline,
            InvokeArgs=json.dumps({
                'trigger': 'evented',
                'uuid': uuid_folder
            })
        )
        LOGGER.debug(response)
        LOGGER.info('Executed %s on %s', pipeline, uuid_folder)