data "aws_iam_policy_document" "main_ecr_policy" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${concat(formatlist("arn:aws:iam::%s:root", var.readonly_accounts), var.readonly_roles)}"]
    }
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    principals {
      type = "AWS"
      identifiers = ["${concat(formatlist("arn:aws:iam::%s:root", var.readwrite_accounts), var.readwrite_roles)}"]
    } 
  }
}