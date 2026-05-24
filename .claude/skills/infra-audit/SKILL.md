---
name: infra-audit
description: Parallel infrastructure audit — security, cost, and drift checks
context: fork
disable-model-invocation: true
---

Run three parallel audits using the custom project agents and compile a unified report.

Launch these three checks in parallel using the Task tool:

**security-auditor agent:**
- Use the `security-auditor` subagent to audit all terraform/*.tf files
- It will check for public S3 buckets, missing encryption, overly permissive IAM, missing HTTPS redirect, and more
- Returns findings as CRITICAL/HIGH/MEDIUM/LOW severity

**cost-optimizer agent:**
- Use the `cost-optimizer` subagent to review all terraform/*.tf files
- It will identify cost-incurring resources and suggest optimizations
- Returns recommendations with estimated impact

**drift-detector agent:**
- Use the `drift-detector` subagent to check for infrastructure drift
- It will run `terraform plan -detailed-exitcode` and analyze any drift found

After all three complete, compile a single report with sections:
## Security Findings
## Cost Optimization
## Drift Status
