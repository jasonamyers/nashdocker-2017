// The ECR ARN
output "arn" {
  value = "${aws_ecr_repository.main.arn}"
}