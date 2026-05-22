# Examples

This directory holds sanitized example output and reference files that complement the main configurations in this repository.

## Layout

```
examples/
  audit-output-sample.txt        — Sample output from audit-gcp-web-project.sh
  cloud-armor-log-sample.txt     — Sample Cloud Armor security event log entries
  iam-policy-export-sample.yaml  — Sample IAM policy export structure
```

## Notes

- All examples use `PROJECT_ID`, `PROJECT_NUMBER`, and similar variables as placeholders
- All examples use `example.com` for domain names
- All service account emails use the format `name@PROJECT_ID.iam.gserviceaccount.com` (clearly placeholder)
- All IP addresses use the documentation reserved range `203.0.113.0/24`
- Example output reflects a hypothetical environment, not any real production system
- The Google Cloud IP ranges shown for health checks (`35.191.0.0/16`, `130.211.0.0/22`) and IAP tunneling (`35.235.240.0/20`) are public infrastructure ranges sourced from Google Cloud documentation, not sensitive
