---
name: setup-gh-actions
description: Review and validate the GitHub Actions workflow, or create one from scratch
argument-hint: "[create|validate]"
allowed-tools: Read, Write, Grep, Glob
disable-model-invocation: true
---

Review and validate the GitHub Actions workflow in `.github/workflows/`.

Check:
1. The workflow file exists and has valid YAML syntax
2. AWS OIDC authentication is configured correctly (role ARN, region)
3. S3 sync step uses correct bucket name and exclude patterns
4. CloudFront invalidation step uses correct distribution ID
5. Trigger is set to push on main branch

If $ARGUMENTS contains "create", generate the complete workflow file.
If $ARGUMENTS contains "validate", only validate the existing file.

Report any issues found and suggest fixes.
