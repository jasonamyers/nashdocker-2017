resource "aws_cloudwatch_event_rule" "pipeline-daily" {
    is_enabled = "false"
    name = "pipeline-daily"
    description = "pipeline ETL daily load"
    schedule_expression = "cron(30 11 * * ? *)"
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule = "${aws_cloudwatch_event_rule.pipeline-daily.name}"
  target_id = "TriggerPipelineLambda"
  arn = "arn:aws:lambda:us-east-1:${var.aws_account_id}:function:pipeline_daily"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id   = "AllowExecutionFromCloudWatch"
  action         = "lambda:InvokeFunction"
  function_name  = "TriggerPipelineLambda"
  principal      = "events.amazonaws.com"
  source_account = "${var.aws_account_id}"
  source_arn     = "${aws_cloudwatch_event_rule.pipeline-daily.arn}"
}