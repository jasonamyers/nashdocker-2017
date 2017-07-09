import boto3
import logging

log = logging.getLogger()
log.setLevel(logging.DEBUG)

client = boto3.client('ecs')

pipelines = [
    'pipeline'
]


def handle(event, context):
    log.info('Running pipeline to load all data')

    task_ids = []

    for pipeline in pipelines:
        response = client.run_task(
            cluster='pipeline_evs',
            taskDefinition='pipeline',
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

    res = 'Launched the pipeline tasks: {}'.format(task_ids)
    log.info(res)
    return res


if __name__ == '__main__':
    handle(None, None)