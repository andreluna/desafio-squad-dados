output "workgroup" {
  value = aws_athena_workgroup.maxmilhas_desafio.name
}

output "bucket_for_database" {
  value = aws_s3_bucket.athena_bucket.bucket
}
