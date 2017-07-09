module "ecr" {
  source   = "./modules/ecr"
  name     = "pipeline-container"
  env      = "${var.env}"
  readonly_accounts = [
    "${var.aws_account_id}",
  ]
#  readwrite_roles = ["SOME ROLE ARN THAT CAN PUSH HERE"]
}