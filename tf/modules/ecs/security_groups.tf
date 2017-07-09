# ECS cluster security group
resource "aws_security_group" "main_ecs" {
  name        = "${var.name}_ecs"
  description = "Allow traffic to the ${var.name} ecs instances"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name        = "${var.name}_ecs"
    Description = "Cluster security group for ${var.name}"
    Environment = "${var.env}"
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group_rule" "allow_all_inbound_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = "${aws_security_group.main_ecs.id}"
}

resource "aws_security_group_rule" "allow_all_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.main_ecs.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.main_ecs.id}"
}