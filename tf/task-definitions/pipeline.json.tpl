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
          "containerPort": 5020,
          "hostPort": 5020
      }
    ],
    "hostname": null,
    "essential": true,
    "entryPoint": null,
    "mountPoints": [],
    "name": "blueprint_admin",
    "ulimits": null,
    "dockerSecurityOptions": null,
    "environment": [
      {"name": "ENVIRONMENT", "value": "${env}",
      {"name": "AWS_REGION", "value": "us-east-1"}
    ],
    "links": null,
    "workingDirectory": null,
    "readonlyRootFilesystem": null,
    "image": "${image_name}",
    "command": null,
    "user": null,
    "dockerLabels": null,
    "logConfiguration": null,
    "cpu": 512,
    "privileged": null
  }
]