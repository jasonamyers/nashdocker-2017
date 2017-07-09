resource "aws_ecs_cluster" "main" {
  name = "${var.name}"
}

# Data source that grabs info for the latest AWS ECS AMI
data "aws_ami" "amazon_ecs" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-*-amazon-ecs-optimized",
    ]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.txt.tpl")}"

  vars {
    name = "${var.name}"
  }
}

# launch config w/ userdata that pulls/starts logspout
resource "aws_launch_configuration" "main_ecs" {
  name_prefix          = "${var.name}_ecs_"
  image_id             = "${data.aws_ami.amazon_ecs.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.main_ecs.name}"
  key_name             = "${var.ssh_key_name}"
  placement_tenancy    = "${var.tenancy}"

  security_groups = ["${compact(list(aws_security_group.main_ecs.id, var.efs_security_group))}"]

  user_data         = "${data.template_file.user_data.rendered}"
  enable_monitoring = true

  lifecycle {
    create_before_destroy = true
  }
}

# asg
resource "aws_autoscaling_group" "main_ecs" {
  name                      = "${var.name}_ecs"
  max_size                  = "${var.asg_max_size}"
  min_size                  = "${var.asg_min_size}"
  desired_capacity          = "${var.asg_desired}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.main_ecs.name}"

  vpc_zone_identifier = [
    "${var.subnet_ids}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Description"
    value               = "Member of ${var.name} ECS"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }
}

resource "aws_sns_topic" "ecs_autoscaling_notification_topic" {
  name = "${var.name}-autoscaling-notification-topic-${var.env}"
}

resource "aws_autoscaling_notification" "ecs_autoscaling_notification" {
  group_names = ["${aws_autoscaling_group.main_ecs.name}"]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "${aws_sns_topic.ecs_autoscaling_notification_topic.arn}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-ecs-cpu-reservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "85"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main_ecs.name}"
  }

  alarm_description = "This metric monitor ecs cpu reservations"
  alarm_actions     = ["${aws_autoscaling_policy.jb_growth_cpu.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-ecs-cpu-reservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "45"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main_ecs.name}"
  }

  alarm_description = "This metric monitor ecs cpu reservations"
  alarm_actions     = ["${aws_autoscaling_policy.jb_shrink_cpu.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name}-ecs-memory-reservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "75"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main_ecs.name}"
  }

  alarm_description = "This metric monitor ecs memory reservations"
  alarm_actions     = ["${aws_autoscaling_policy.jb_growth_memory.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${var.name}-ecs-memory-reservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "45"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main_ecs.name}"
  }

  alarm_description = "This metric monitors ecs memory reservations"
  alarm_actions     = ["${aws_autoscaling_policy.jb_shrink_memory.arn}"]
}

resource "aws_autoscaling_policy" "jb_growth_cpu" {
  name                   = "grow_cpu"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 150
  autoscaling_group_name = "${aws_autoscaling_group.main_ecs.name}"
}

resource "aws_autoscaling_policy" "jb_shrink_cpu" {
  name                   = "shrink_cpu"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 150
  autoscaling_group_name = "${aws_autoscaling_group.main_ecs.name}"
}

resource "aws_autoscaling_policy" "jb_growth_memory" {
  name                   = "grow_memory"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 150
  autoscaling_group_name = "${aws_autoscaling_group.main_ecs.name}"
}

resource "aws_autoscaling_policy" "jb_shrink_memory" {
  name                   = "shrink_memory"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 150
  autoscaling_group_name = "${aws_autoscaling_group.main_ecs.name}"
}

