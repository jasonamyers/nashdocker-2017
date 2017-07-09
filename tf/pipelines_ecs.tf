module "ecs" {
  source                 = "./modules/ecs"
  vpc_id                 = "${module.vpc.id}"
  subnet_ids             = "${module.vpc.private_subnets}"
  env                    = "${var.env}"
  name                   = "pipelines_ecs"
  ssh_key_name           = "${aws_key_pair.default.key_name}"
  logging_redis_endpoint = "${module.logging.logging_redis_endpoint}"
  efs_security_group     = "${module.docker_efs.security_group_id}"
  instance_type          = "m4.large"
  tenancy                = "default"
  asg_min_size           = "0"
  asg_max_size           = "2"
  asg_desired            = "0"
}

# Time based scaling up and down
resource "aws_autoscaling_schedule" "ramp_up" {
  scheduled_action_name  = "ramp_up"
  min_size               = 0
  max_size               = 2
  desired_capacity       = 1
  recurrence             = "40 10 * * *"
  autoscaling_group_name = "${module.pipelines_ecs.autoscaling_group_name}"
}

resource "aws_autoscaling_schedule" "ramp_down" {
  scheduled_action_name  = "ramp_down"
  min_size               = 0
  max_size               = 2
  desired_capacity       = 0
  recurrence             = "0 12 * * *"
  autoscaling_group_name = "${module.pipelines_ecs.autoscaling_group_name}"
}