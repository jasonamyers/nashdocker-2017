data "aws_iam_policy_document" "pipeline-task" {

    statement {
      sid = "AllowServiceToListRedshiftS3Bucket"
      effect = "Allow"
      actions = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::upload-bucket"]
    }
    statement {
      sid = "AllowServiceToGetandPutS3BucketLimited"
      effect = "Allow"
      actions =  [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      resources = ["arn:aws:s3::upload-bucket/*"]
    }
}

resource "aws_iam_policy" "pipeline-task" {
    name = "pipeline-task"
    description = "Allow pipeline ECS task to access S3"
    policy = "${data.aws_iam_policy_document.pipeline-task.json}"
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

resource "aws_iam_role" "pipeline-task" {
  name = "pipeline-task"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_sts_assume_role_policy.json}"
}

resource "aws_iam_policy_attachment" "pipeline-task-attach" {
  name = "pipeline-prod-task-attach"
  roles = ["${aws_iam_role.pipeline-task.name}"]
  policy_arn = "${aws_iam_policy.pipeline-task.arn}"
}

data "aws_iam_policy_document" "pipeline-lamdba-ecs" {
    statement {
        sid = "AllowLambdaToLaunchECS"
        effect = "Allow"
        actions = ["ecs:RunTask"]
        resources = ["arn:aws:ecs:us-east-1:${var.aws_account_id}:task-definition/pipeline"]
    }
}

resource "aws_iam_policy" "pipeline-lambda-ecs" {
    name = "pipeline-lambda-ecs"
    description = "Allow pipeline lambda to launch ecs"
    policy = "${data.aws_iam_policy_document.pipeline-lamdba-ecs.json}"
}


resource "aws_iam_policy_attachment" "pipeline-lambda-ecs-attach" {
  name = "pipeline-lambda-ecs-attach"
  roles = ["pipeline_lambda_function"]
  policy_arn = "${aws_iam_policy.pipeline-lambda-ecs.arn}"
}