---
name: project-infra-patterns
description: Recurring security patterns observed in this project's Terraform and CI/CD — used to orient future audits
metadata:
  type: project
---

This project uses S3 + CloudFront (OAC) for static site hosting, with GitHub Actions OIDC for CI/CD auth. Terraform state is managed via an S3 backend with DynamoDB locking (currently commented out in backend.tf).

**Why:** Static portfolio site for a DevOps course — infrastructure is intentionally minimal but production-style.

**How to apply:** Future audits should focus on: hardcoded ARNs/account IDs leaking into CI/CD YAML, missing S3 encryption-at-rest, absent CloudFront access logging, security headers, and whether the backend S3 block remains commented out (local state risk).

Known recurring issues — confirmed in re-audit (2026-05-23):
- S3 bucket missing server-side encryption (aws_s3_bucket_server_side_encryption_configuration) — main.tf
- No CloudFront access logging configured — main.tf
- No CloudFront security response headers policy (CSP, X-Frame-Options, HSTS, X-Content-Type-Options, Referrer-Policy) — main.tf
- TLS uses cloudfront_default_certificate with no minimum_protocol_version — defaults to TLSv1, must be TLSv1.2_2021 — main.tf line 131-133
- Remote state backend block commented out; state is local only — backend.tf
- Custom error response maps 404 → 200 (cosmetic/SPA pattern, not a security issue) — main.tf line 116-121
- deploy.yml now uses GitHub secrets for role ARN, bucket name, and distribution ID (hardcoded account ID issue from prior audit is resolved)
- deploy.yml region (eu-north-1) does not match variables.tf default region (eu-west-1) — indicates possible misconfiguration
- No S3 access logging enabled on the site bucket — main.tf
- OAC configuration is correct (signing_behavior=always, signing_protocol=sigv4) — positive finding
- S3 public access block is fully configured (all four flags true) — positive finding
- IAM policy for OAC bucket access is least-privilege (s3:GetObject only, scoped to bucket ARN/* with CloudFront source ARN condition) — positive finding
