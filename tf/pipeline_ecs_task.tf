data "template_file" "pipeline_task_template" {
  template = "${file("task-definitions/pipeline.json.tpl")}"

  vars {
    image_name       = "${var.aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/pipeline-${var.env}:latest"
    env     = "${var.env}"
  }
}

# ecs task definition
resource "aws_ecs_task_definition" "pipeline" {
  family = "pipeline"

  container_definitions = "${data.template_file.pipeline_task_template.rendered}"
  task_role_arn = "${aws_iam_role.pipeline-task.arn}"
}