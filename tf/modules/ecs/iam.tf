resource "aws_iam_role" "ecs_role" {
  name               = "${var.name}_ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_sts_assume_role_policy.json}"
}

resource "aws_iam_instance_profile" "main_ecs" {
  name  = "${var.name}_ecs"
  roles = ["${aws_iam_role.ecs_role.name}"]
}

data "aws_iam_policy_document" "ecs_sts_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ecs.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "instance_role_policy" {
  statement {
    actions = [
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTask",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "elasticfilesystem:DescribeFileSystems",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "instance_role_policy" {
  name   = "${var.name}_instance_role_policy"
  policy = "${data.aws_iam_policy_document.instance_role_policy.json}"
  role   = "${aws_iam_role.ecs_role.id}"
}