[
  {
    "volumesFrom": [],
    "memory": 512,
    "extraHosts": null,
    "dnsServers": null,
    "disableNetworking": null,
    "dnsSearchDomains": null,
    "portMappings": [
        {
            "containerPort": 8000,
            "hostPort": 8000
        }
    ],
    "hostname": null,
    "essential": true,
    "entryPoint": null,
    "mountPoints": [
      {
        "containerPath": "/var/run/docker.sock",
        "sourceVolume": "docker_socket",
        "readOnly": true
      }
    ],
    "name": "logspout",
    "ulimits": null,
    "dockerSecurityOptions": null,
    "environment": [
        {
            "name": "REDIS_KEY",
            "value": "logspout"
        },
        {
            "name": "DEDOT_LABELS",
            "value": "true"
        },
        {
            "name": "DEBUG",
            "value": "true"
        }
    ],
    "links": null,
    "workingDirectory": null,
    "readonlyRootFilesystem": null,
    "image": "rtoma/logspout-redis-logstash:0.1.8",
    "command": [
      "${jb_logging_ec}"
    ],
    "user": null,
    "dockerLabels": null,
    "logConfiguration": null,
    "cpu": 1,
    "privileged": null
  }
]