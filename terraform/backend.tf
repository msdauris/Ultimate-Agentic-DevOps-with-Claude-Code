# ---------------------------------------------------------------------------
# Remote State Backend — S3 + DynamoDB
# ---------------------------------------------------------------------------
# HOW TO ENABLE:
#   1. Create the S3 bucket and DynamoDB table in AWS first (see commands below).
#   2. Run `terraform init` WITHOUT this backend block so Terraform creates
#      any remaining resources defined in main.tf.
#   3. Uncomment the `terraform { backend "s3" … }` block below.
#   4. Run `terraform init -migrate-state` to copy local state to S3.
#
# Resources to create manually before uncommenting:
#   S3 bucket:       dauris-portfolio-site-tfstate   (region: eu-west-1)
#   DynamoDB table:  dauris-portfolio-site-tfstate-lock  (partition key: LockID, type: S)
#
# AWS CLI commands:
#   aws s3api create-bucket \
#     --bucket dauris-portfolio-site-tfstate \
#     --region eu-west-1 \
#     --create-bucket-configuration LocationConstraint=eu-west-1
#
#   aws s3api put-bucket-versioning \
#     --bucket dauris-portfolio-site-tfstate \
#     --versioning-configuration Status=Enabled
#
#   aws dynamodb create-table \
#     --table-name dauris-portfolio-site-tfstate-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region eu-west-1
# ---------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket       = "dauris-portfolio-site-tfstate"
    key          = "dauris-portfolio-site/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}
