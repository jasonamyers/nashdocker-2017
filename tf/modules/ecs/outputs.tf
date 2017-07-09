// The ECS instance role ARN
output "role_arn" {
  value = "${aws_iam_role.ecs_role.arn}"
}

// The ECS cluster name
output "cluster_name" {
  value = "${aws_ecs_cluster.main.name}"
}

// The ECS cluster security group
output "security_group" {
  value = "${aws_security_group.main_ecs.id}"
}

// The ECS cluster Autoscaling Group Name
output "autoscaling_group_name" {
  value = "${aws_autoscaling_group.main_ecs.name}"
}