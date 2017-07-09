resource "aws_kinesis_stream" "s3_event_stream" {
  name        = "s3_event_stream"
  shard_count = 1

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags {
    Name        = "s3-event-stream"
    Description = "Holds s3 events for automatic pipeline triggering"
    Environment = "${var.env}"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_event_source_mapping" "s3_event_source_mapping" {
  event_source_arn  = "${aws_kinesis_stream.s3_event_stream.arn}"
  function_name     = "${var.s3-events-watcher}"
  starting_position = "LATEST"
}
