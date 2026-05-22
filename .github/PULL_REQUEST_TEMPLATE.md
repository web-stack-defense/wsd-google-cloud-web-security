# Pull Request

## Summary

<!-- What does this PR change? -->

## Linked issue

<!-- Reference the issue that was opened first to discuss scope. PRs without a prior issue are unlikely to be merged. -->

Closes #

## Type of change

- [ ] Correction to existing content
- [ ] New Cloud Armor rule or policy
- [ ] New IAM least-privilege pattern
- [ ] New VPC firewall or load balancer reference
- [ ] New Cloud Logging filter
- [ ] New diagnostic script
- [ ] Documentation update
- [ ] Other (describe below)

## Sanitization confirmation

- [ ] No real project IDs or project numbers appear (uses `PROJECT_ID`, `PROJECT_NUMBER`)
- [ ] No real service account email addresses appear (uses `name@PROJECT_ID.iam.gserviceaccount.com`)
- [ ] No real OAuth2 client IDs or secrets appear
- [ ] No real KMS key resource names appear
- [ ] No real domain names appear (uses `example.com`)
- [ ] No real IP addresses appear (uses `203.0.113.0/24` or documented Google IP ranges only)
- [ ] Any new placeholder values are clearly marked as placeholders

## Google Cloud accuracy

- [ ] Cloud Armor preconfigured WAF rule names use current CRS 4.22 naming (`*-v422-stable`), not deprecated `-v33-stable` or `-v3-stable`
- [ ] Cloud Armor signature IDs use current format (`owasp-crs-v042200-idNNNNNN-{category}`)
- [ ] IAM role IDs are exact predefined roles verified against [Google Cloud IAM documentation](https://cloud.google.com/iam/docs/understanding-roles)
- [ ] gcloud command syntax has been verified against current Google Cloud documentation
- [ ] Product names use current Google Cloud naming (e.g., "External Application Load Balancer", not "HTTP/HTTPS Load Balancer")

## Validation

- [ ] Changes have been tested against at least one environment documented in TESTED_ON.md
- [ ] If a new gcloud command is added, inline comments explain the reason for each flag
- [ ] If a new script is added, it has been tested and does not modify GCP resources unless explicitly stated
- [ ] Shell scripts pass `bash -n` syntax check

## Notes for reviewers

<!-- Anything reviewers should pay particular attention to. -->
