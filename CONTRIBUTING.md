# Contributing

This repository is part of [Web Stack Defense](https://www.webstackdefense.com). Content here is curated to maintain consistency with the platform's editorial standards.

Issues and curated pull requests are allowed, but this is not an open-ended community repository where every submission will be merged.

## Before Opening an Issue

- Check the existing issues to confirm the topic is not already covered
- Confirm the issue is about content in this repository, not about Google Cloud product behavior
- For security issues in the content itself, follow [SECURITY.md](SECURITY.md) instead

## Before Opening a Pull Request

Open an issue first to discuss scope. Pull requests submitted without prior discussion are unlikely to be merged.

## Contribution Standards

All contributions must:

- Use current Google Cloud product names (not deprecated names like "Cloud HTTP/HTTPS Load Balancer" — current name is "External Application Load Balancer")
- Use current Cloud Armor preconfigured WAF rule names (CRS 4.22, `*-v422-stable`) — NOT the deprecated `-v33-stable` or `-v3-stable` names
- Use exact predefined IAM role IDs (e.g., `roles/secretmanager.secretAccessor`) verified against current Google Cloud documentation
- Be sanitized of any real project IDs, project numbers, service account emails, OAuth2 client IDs, KMS key names, or production resource names
- Use `PROJECT_ID` and `PROJECT_NUMBER` as placeholder variables
- Use `example.com` for domain examples
- Use `203.0.113.0/24` for IP address examples
- Include source attribution where derived from external work (Google Cloud documentation, CIS GCP benchmark)
- Match the existing file structure and naming conventions
- Include inline comments explaining the reason for each command or directive
- Be tested against at least one of the environments documented in [TESTED_ON.md](TESTED_ON.md)

## What Is Out of Scope

- Terraform modules (this repository documents gcloud CLI commands; IaC implementations are out of scope here)
- GKE-specific hardening (covered separately if at all)
- BigQuery, Dataflow, or other data engineering workloads
- Anthos / Hybrid deployments
- Organization or folder-level policies (this repository scopes to project-level web workloads)

## Scope Reminder

This repository covers Google Cloud security configurations scoped specifically to public-facing websites and web applications. Enterprise security frameworks, organization policies, and non-web workloads are outside the scope of this repository.
