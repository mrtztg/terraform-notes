provider "aws" {
	region = "eu-west-2"
}

resource "aws_s3_bucket" "practice_bucket" {
	bucket = "mory_practice_bucket"
}
