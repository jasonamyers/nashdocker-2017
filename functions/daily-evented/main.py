import base64
import json
import logging
import re
import datetime as dt
import time
from os import path as osp

import boto3


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)

# Change to match the AWS environment
STREAM_NAME = 's3_event_stream'
SHARD_ID = 'shardId-000000000000'


ECS = boto3.client('ecs')
KINESIS = boto3.client('kinesis')


CONFIG = {
    'pipelines': ['pipeline'],
    'filenames': ['file1.csv', 'file2.csv', 'file3.csv']
}


def get_bucket_name(event):
    return event['Records'][0]['s3']['bucket']['name']


def get_key(event):
    return event['Records'][0]['s3']['object']['key']


def get_uuid(key):
    uuid_path = osp.dirname(key)
    return osp.basename(uuid_path)


def get_file(key):
    return osp.basename(key)


def get_filenames_in_kinesis_stream(uuid):
    """ Searches within the past hour for S3 PUT events
    in Kinesis that match the supplied UUID.

    Parameters
    ----------
    uuid : str
        The UUID related to the JBCLI upload session.  All relevant
        files will have this UUID in their key.

    Returns
    -------
    found_files : list of str
        A list of all the files that match the names/regexes
        supplied in the CONFIG object.
    """
    found_files = []
    now = dt.datetime.utcnow()
    past_hour = now - dt.timedelta(hours=1)

    shard_iter = KINESIS.get_shard_iterator(
        StreamName=STREAM_NAME,
        ShardId=SHARD_ID,
        ShardIteratorType='AT_TIMESTAMP',
        Timestamp=past_hour)["ShardIterator"]

    done = False
    LOGGER.info('Processing the Stream')

    while not done:
        shard_records = KINESIS.get_records(
            ShardIterator=shard_iter, Limit=100
        )
        LOGGER.info('Shard Records: %s', shard_records)

        if shard_records.get('MillisBehindLatest') == 0:
            done = True

        if 'NextShardIterator' in shard_records:
            shard_iter = shard_records['NextShardIterator']
        else:
            done = True
            continue

        for shard_record in shard_records.get('Records', []):
            data_blob = shard_record['Data']
            LOGGER.info("DATA %s", data_blob)
            s3_event = json.loads(data_blob)
            key = get_key(s3_event)
            event_uuid = get_uuid(key)
            filename = get_file(key)
            if not event_uuid == uuid:
                continue
            for regex in CONFIG['filenames']:
                if re.search(regex, filename):
                    found_files.append(filename)

        time.sleep(0.5)

    return found_files


def handle(event, context):
    """Switch to determine what handler to run."""
    LOGGER.info("EVENT: %s", event)
    LOGGER.info("CONTEXT: %s", context)

    if event and event.get('trigger') == 'evented':
        event_handle(event, context)
    else:
        legacy_handle(event, context)


def event_handle(event, context):
    """Handler to read in the event data and make sure all specified
    files have been located before launching the pipeline."""
    event_uuid = event.get('uuid')
    found_files = get_filenames_in_kinesis_stream(event_uuid)
    if sorted(found_files) == sorted(CONFIG['filenames']):
        legacy_handle(event, context)


def legacy_handle(event, context):
    """Handler for executing the pipeline in ECS."""
    LOGGER.info('Running pipelines for uvagd to load all data')

    task_ids = []

    for pipeline in CONFIG['pipelines']:
        response = ECS.run_task(
            cluster='public_internal',
            taskDefinition='etl-uvagd',
            count=1,
            overrides={
                'containerOverrides': [
                    {
                        'name': 'pipeline',
                        'command': [
                            'luigi', '--local-scheduler', 'TransformTask',
                            '--module={}'.format(pipeline)
                        ]
                    }
                ]
            }
        )

        if response['failures']:
            email_client = boto3.client('ses')
            email_response = email_client.send_email(
                Source='luigi@place.com',
                Destination={
                    'ToAddresses': [
                        'bob@tom.com',
                    ],
                    'CcAddresses': [],
                    'BccAddresses': []
                },
                Message={
                    'Subject': {
                        'Data': 'ETL {} failed'.format(pipeline),
                    },
                    'Body': {
                        'Text': {
                            'Data': 'Pipeline {} failed due to {}'.format(
                                pipeline, response['failures'][0]['reason']),
                        }
                    }
                }
            )
        elif response['tasks']:
            task_ids.append(response['tasks'][0]['taskArn'])

    task_ids = ', '.join(task_ids)

    res = 'Launched the etl-uvagd tasks: {}'.format(task_ids)
    LOGGER.info(res)
    return res


if __name__ == '__main__':
    handle(None, None)