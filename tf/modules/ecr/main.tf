resource "aws_ecr_repository" "main" {
  name = "${var.name}-${var.env}"
}

resource "aws_ecr_repository_policy" "main" {
  repository = "${aws_ecr_repository.main.name}"
  policy     = "${data.aws_iam_policy_document.main_ecr_policy.json}"
}