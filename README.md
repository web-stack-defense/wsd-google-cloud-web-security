# Google Cloud Web Security

Sanitized Google Cloud security content scoped specifically to websites and web applications running on GCP.

This repository focuses on practical Cloud Armor security policies, IAM least-privilege patterns for web workloads, VPC firewall baselines for web-facing GCP environments, Cloud Logging configuration for web traffic, load balancer hardening, and operator-safe implementation guidance. It is meant to be useful to defenders running web workloads on Google Cloud, and readable to engineers or business owners reviewing the work.

This repository is maintained by a Google Cloud Professional Security Engineer (PSE).

## Scope

This repository includes:

- Cloud Armor security policy expressions using current (CRS 4.22) preconfigured WAF rules
- Cloud Armor rate limiting policies
- IAM least-privilege role bindings for common web workload service accounts
- VPC firewall rule examples for web-facing deployments
- HTTPS load balancer hardening references (SSL policies, security policy attachment)
- Cloud Logging filter examples for web traffic
- gcloud CLI scripts for read-only audits
- Documentation written around manual deployment, validation, rollback, and tuning discipline

This repository does not include:

- Terraform modules or full Infrastructure-as-Code automation
- Scripts that modify production GCP resources without confirmation
- Configurations for enterprise data engineering workloads
- General GCP security beyond what affects web applications
- GKE-specific hardening (out of scope here, may be covered separately)
- Claims that every example here is universally safe to deploy without tuning

## Why this repository exists

A lot of public GCP security content is either enterprise-data-engineering-flavored (BigQuery, Dataflow, data perimeters), too tied to a specific company's stack, or out of date with current Cloud Armor and IAM defaults. The goal here is different:

- keep the structure clean
- keep the scope honest — websites and web applications running on GCP, not GCP in general
- use only current, documented APIs, role IDs, and preconfigured WAF rule names
- document real operational tradeoffs
- make validation and rollback first-class parts of the workflow

## Who this is for

This repository is aimed at:

- Site reliability engineers running websites on GCP
- DevOps engineers managing web workloads on Cloud Run, App Engine, or Compute Engine
- Security engineers handling GCP web environments
- Blue team engineers responsible for GCP-hosted public services
- Business owners reviewing the work of Web Stack Defense

## Baseline environment

The content in this repository was shaped against real GCP web deployments running:

- External Application Load Balancer (global and regional)
- Cloud Armor security policies with OWASP CRS 4.22 preconfigured WAF rules
- Cloud Run services with managed runtime
- Compute Engine instances with web workloads
- Cloud Logging with structured log entries
- Secret Manager for application credentials
- Cloud CDN for static asset delivery
- Identity-Aware Proxy (IAP) for admin and staging environments

For exact version notes, see [TESTED_ON.md](TESTED_ON.md).

## Repository layout

```
configs/
  cloud-armor/
  iam/
  vpc-firewall/
  load-balancer/
  logging/

checklists/

scripts/

examples/
```

## Content design

The repository is intentionally split into:

**Cloud Armor security policies**
gcloud CLI commands and policy expressions for deploying Cloud Armor security policies. Every rule uses current Rules Language syntax with `evaluatePreconfiguredWaf()` referencing CRS 4.22 (`xss-v422-stable`, `sqli-v422-stable`, etc.). All rules are designed to be deployed in `preview` mode first, then promoted to enforcement after log review.

**IAM least-privilege patterns**
Example IAM role bindings for the service accounts that commonly back web workloads: Cloud Run runtime, deployer pipeline, log writer, secret reader. Roles are referenced by their exact predefined role IDs (`roles/secretmanager.secretAccessor`, `roles/logging.logWriter`, etc.) verified against current Google Cloud documentation.

**VPC firewall and load balancer**
Firewall rules that restrict ingress to GFE health-check ranges and the Google Front End. Load balancer hardening that includes SSL policies aligned to the RESTRICTED profile and Cloud Armor attachment to backend services.

**Cloud Logging**
Log filter expressions for surfacing the events that matter on web workloads: Cloud Armor security events, load balancer 4xx/5xx spikes, IAM permission changes, and IAP authentication failures.

**Checklists**
Operational checklists for initial deployment, IAM review, and Cloud Armor tuning.

**Scripts**
Read-only gcloud-based audit scripts that report current state. No script in this repository modifies a live GCP resource.

## Installation philosophy

This repository assumes manual deployment.

That is deliberate.

GCP resources have real billing impact, real blast radius (a misconfigured Cloud Armor policy can take a site offline; an over-broad IAM grant exposes secrets), and real complexity around region scoping, project boundaries, and IAM inheritance. The realistic value of a public GCP security repo is as a reference to adapt, not a copy-paste deployment.

Review the gcloud command. Understand which resource it modifies. Deploy Cloud Armor policies in `preview` mode first. Validate IAM bindings with `gcloud asset search-all-iam-policies` before assuming least-privilege is achieved. Keep an alternate access method open during firewall and IAM changes.

## Validation workflow

Recommended order for any change:

1. Review the gcloud command and confirm the resource being modified
2. Confirm the project, region, and account context (`gcloud config list`)
3. Run with `--dry-run` if available, or in a non-production project first
4. For Cloud Armor: deploy rules in `preview` mode (`--preview` flag)
5. Apply the change
6. For Cloud Armor: review matched requests in Security Logs for 24 to 72 hours
7. For IAM: verify the principal can still perform expected actions and cannot perform unexpected ones
8. For firewall: verify the site is still reachable from the public internet
9. Promote Cloud Armor rules out of preview only after log review
10. Document the change with timestamp, command, and result

## Risks and guardrails

This repository assumes you understand the following risks:

- Cloud Armor rules in enforcement mode can block legitimate traffic if not tuned first
- IAM changes can take 2 to 7 minutes to propagate (recent grants may not work immediately)
- IAM grants at higher levels (folder, organization) override what looks like a least-privilege grant at the project level
- VPC firewall rules apply by priority — a high-priority allow rule overrides a deny rule with higher numeric priority
- Removing IAM roles can lock service accounts out of required APIs
- Deleting a security policy attached to a backend service does not detach it cleanly — detach first
- SSL policies set at MODERN or RESTRICTED can break legacy clients
- Cloud CDN cache poisoning is possible if cache keys are misconfigured
- IAP requires correctly configured OAuth2 client credentials — misconfiguration locks out admins

## Redaction policy

Nothing in this repository should expose:

- real project IDs or project numbers
- real service account email addresses
- real OAuth2 client IDs or client secrets
- real KMS key resource names
- real Cloud Armor policy names from production
- real IP addresses tied to actual deployments

All examples use `PROJECT_ID` and `PROJECT_NUMBER` as placeholder variables, `example.com` for domain names, and the documentation reserved range `203.0.113.0/24` for IP addresses. Service account emails use the format `service-account-name@PROJECT_ID.iam.gserviceaccount.com`.

## Affiliate disclosure

Some setup notes may reference Google Cloud Marketplace partners or related commercial tools using affiliate links. If you choose to use one, Web Stack Defense may receive a referral credit at no extra cost to you. Support is appreciated, but use whatever tooling fits your environment.

## Related platform

This repository is part of the broader website security work documented at [Web Stack Defense](https://www.webstackdefense.com). Guides on the site go deeper into context, tradeoffs, and implementation decisions. The configurations and scripts here are the practical artifacts that sit alongside those guides.

## Contribution policy

Issues and curated pull requests are allowed, but this is not an open-ended community repo where every submission will be merged.

Security issues should be reported privately according to [SECURITY.md](SECURITY.md).

Contribution standards are documented in [CONTRIBUTING.md](CONTRIBUTING.md).
