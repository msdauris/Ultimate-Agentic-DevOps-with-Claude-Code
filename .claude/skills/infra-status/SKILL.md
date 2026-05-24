---
name: infra-status
description: Check the current infrastructure status and present a health dashboard
allowed-tools: Bash, Read, Grep
disable-model-invocation: true
---

Check the current infrastructure status.

Run these checks and present a summary table:
1. Terraform state: `cd terraform && terraform show -json | head -100` — list all managed resources
2. S3 bucket: `aws s3 ls s3://<bucket>` — verify files exist (get bucket name from terraform output)
3. CloudFront: `aws cloudfront get-distribution --id <dist-id> --query "Distribution.Status"` — verify status is "Deployed"
4. Site health: Fetch the CloudFront URL and check for HTTP 200

Present results as a status dashboard with pass/fail for each check.
