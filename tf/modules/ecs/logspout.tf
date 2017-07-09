data "template_file" "logspout_task_template" {
  template = "${file("${path.module}/logspout_task.json.tpl")}"

  vars {
    jb_logging_ec = "redis://${var.logging_redis_endpoint}"
  }
}

# ecs task definition for logspout
resource "aws_ecs_task_definition" "logspout" {
  family                = "logspout"
  container_definitions = "${data.template_file.logspout_task_template.rendered}"

  volume {
    name      = "docker_socket"
    host_path = "/var/run/docker.sock"
  }
}

