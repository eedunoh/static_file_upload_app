resource "aws_kms_key" "s3_sensitive_key" {
  description             = "KMS key for encrypting sensitive S3 objects"
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3_sensitive_key_alias" {
  name          = "alias/s3-sensitive-key"
  target_key_id = aws_kms_key.s3_sensitive_key.id
}


output "kms_master_key_id" {
  value = aws_kms_key.s3_sensitive_key.id
}
