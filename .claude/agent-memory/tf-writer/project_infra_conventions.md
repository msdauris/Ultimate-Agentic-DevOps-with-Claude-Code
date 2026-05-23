---
name: project-infra-conventions
description: Key Terraform conventions and resource naming for the dauris-portfolio-site project
metadata:
  type: project
---

Project name variable default: `dauris-portfolio-site`
Environment variable default: `production`
Provider region: `eu-west-1`

State bucket naming pattern: `{project_name}-tfstate` → `dauris-portfolio-site-tfstate`
DynamoDB lock table: `dauris-portfolio-site-tfstate-lock`
Site S3 bucket naming pattern: `{project_name}-{environment}-site`

Backend block in `backend.tf` is kept commented out until the user manually creates the S3 bucket and DynamoDB table, then runs `terraform init -migrate-state`.

CloudFront uses OAC (not OAI). `viewer_certificate` with `cloudfront_default_certificate = true` must NOT include `ssl_support_method` — AWS rejects that combination. Only `minimum_protocol_version` is set alongside the default cert.

**Why:** AWS API constraint — `ssl_support_method` is only valid with a custom ACM certificate.
**How to apply:** Any CloudFront `viewer_certificate` block using the default cert gets only `cloudfront_default_certificate = true` and `minimum_protocol_version = "TLSv1.2_2021"`.
