################################################################################
# Outputs
#

output "s3_bucket_id" {
  description = "ID/FQDN of the S3 bucket."
  value       = aws_s3_bucket.artifacts.id
}
