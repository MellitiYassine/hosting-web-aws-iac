
# S3 Bucket for JAR Files
resource "aws_s3_bucket" "ecommerce_jar_bucket" {
  bucket = "ecommerce-jar-bucket-${random_id.bucket_suffix.hex}" # Unique bucket name

  tags = {
    Name = "ecommerce-jar-bucket"
  }
}

# Random ID for S3 Bucket Name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}