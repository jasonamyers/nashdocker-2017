import json
import logging
import sys

import boto3

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)

# Change to match the AWS environment
STREAM_NAME = 's3_event_stream'
SHARD_ID = 'shardId-000000000000'
STREAM_PART = '1'

KINESIS = boto3.client('kinesis')
S3 = boto3.resource('s3')


def get_bucket_name(event):
    return event['Records'][0]['s3']['bucket']['name']


def get_key_name(event):
    return event['Records'][0]['s3']['object']['key']


def build_new_key_name(old_key_name):
    key_parts = old_key_name.split('/')
    app_folder = '/'.join(key_parts[:2])
    key_name = key_parts[-1]
    return '{}/listen/{}'.format(app_folder, key_name)


def publish_event_to_kinesis(key_name, event):
    partition_key = key_name.split('/')[0] or 'Not Available'
    LOGGER.info('Publishing event to Kinesis Stream')
    KINESIS.put_record(
        StreamName=STREAM_NAME,
        Data=json.dumps(event),
        PartitionKey=partition_key
    )


def copy_to_listen_prefix(bucket_name, key_name):
    copy_source = {
        'Bucket': bucket_name,
        'Key': key_name
    }

    bucket = S3.Bucket(bucket_name)
    new_key_name = build_new_key_name(key_name)
    LOGGER.info('Copying from {} to {} in {}'.format(
        key_name, new_key_name, bucket_name))
    obj = bucket.Object(new_key_name)
    obj.copy_from(CopySource=copy_source, ServerSideEncryption='AES256')


def handle(event, context):
    LOGGER.info('{}-{}'.format(event, context))

    bucket_name = get_bucket_name(event)
    key_name = get_key_name(event)
    if 'redshift' in key_name or 'archive' in key_name or \
            'listen' in key_name:
        return event

    copy_to_listen_prefix(bucket_name, key_name)
    publish_event_to_kinesis(key_name, event)

    return event