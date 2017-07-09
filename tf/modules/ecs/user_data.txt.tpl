#!/bin/bash
echo ECS_CLUSTER=${name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config

start ecs

set -x
until curl -s http://localhost:51678/v1/metadata
do
  sleep 1
done

yum install -y jq aws-cli nfs-utils

# Grab the container instance ARN and AWS region from instance metadata
instance_arn=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $NF}' )
cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster' | awk -F/ '{print $NF}' )
region=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F: '{print $4}')

# Specify the task definition to run at launch
task_definition=logspout

# Run the AWS CLI start-task command to start your task on this container instance
aws ecs start-task --cluster $cluster \
                   --task-definition $task_definition \
                   --container-instances $instance_arn \
                   --started-by $instance_arn \
                   --region $region


# Attach EFS storage for apps
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EFS_FILE_SYSTEM_ID=`aws efs describe-file-systems --region $region | jq '.FileSystems[]' | jq 'select(.Name=="docker_volumes")' | jq -r '.FileSystemId'`
if [-z "$EFS_FILE_SYSTEM_ID"]; then
       	echo "ERROR: variable not set" 1> /etc/efssetup.log
       	exit
fi
mkdir -p /mnt/efs
DIR_SRC=$EC2_AVAIL_ZONE.$EFS_FILE_SYSTEM_ID.efs.$region.amazonaws.com
DIR_TGT=/mnt/efs
cp -p /etc/fstab /etc/fstab.back-$(date +%F)
mount -t nfs4 $DIR_SRC:/ $DIR_TGT
echo -e "$DIR_SRC:/ \t\t $DIR_TGT \t\t nfs \t\t defaults \t\t 0 \t\t 0" | tee -a /etc/fstab