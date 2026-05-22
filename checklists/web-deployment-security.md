# GCP Web Workload Security Checklist

Comprehensive checklist for deploying a public-facing web workload on Google Cloud. Use during initial deployment or as a quarterly audit.

## Pre-flight

- [ ] GCP project is dedicated to this workload (or has clear logical separation)
- [ ] Billing account is correct and budget alerts are configured
- [ ] gcloud CLI is updated to a recent version (`gcloud components update`)
- [ ] You have Editor or higher on the project (for setup) — downgrade after deployment
- [ ] A non-production project exists for testing changes before production

## Project-Level IAM

- [ ] Project Owner is restricted to a small, documented set of principals
- [ ] No service accounts have Project Owner or Project Editor
- [ ] Default service accounts (`PROJECT_NUMBER-compute@`, `PROJECT_ID@appspot`) are disabled OR documented as required
- [ ] No human users have Project Owner unless explicitly required
- [ ] Service account key creation is monitored (Cloud Logging filter — see `configs/logging/security-filters.txt` Filter 6)

## Service Accounts

For each workload service account:

- [ ] Named purposefully (e.g., `web-app-runtime-sa`, not `service-account-1`)
- [ ] Has only the predefined roles it needs (see `configs/iam/least-privilege-patterns.txt`)
- [ ] Secret Manager access is granted at the SECRET level, NOT project level
- [ ] No service account keys exist unless absolutely required (workload identity is preferred)
- [ ] Service account keys, if they exist, are rotated regularly and stored in Secret Manager or equivalent

## Cloud Armor

- [ ] At least one Cloud Armor security policy exists in the project
- [ ] Policy is attached to every public-facing backend service
- [ ] OWASP CRS 4.22 preconfigured WAF rules are deployed (see `configs/cloud-armor/owasp-policy.txt`)
- [ ] All rules were initially deployed with `--preview` and reviewed before promotion
- [ ] Rate limiting rules exist for login and other abuse-prone endpoints
- [ ] No rules remain in `preview` mode longer than 30 days (either promote or delete)
- [ ] Default rule (priority 2147483647) action is documented and intentional

## Load Balancer and SSL

- [ ] Target HTTPS proxy has an SSL policy attached (NOT using GCP defaults)
- [ ] SSL policy uses `RESTRICTED` profile, or `MODERN` with documented legacy client requirements
- [ ] Minimum TLS version is 1.2 or higher
- [ ] Certificate is managed (Google-managed certificate or ACM-managed equivalent)
- [ ] Certificate renewal is automatic or has scheduled review
- [ ] HTTP requests redirect to HTTPS

## VPC Firewall (Compute Engine workloads only)

- [ ] No firewall rules allow 0.0.0.0/0 to SSH (port 22)
- [ ] No firewall rules allow 0.0.0.0/0 to RDP (port 3389)
- [ ] No firewall rules allow 0.0.0.0/0 to database ports (3306, 5432, 6379, 27017)
- [ ] Health check ranges (`35.191.0.0/16` and `130.211.0.0/22`) are explicitly allowed
- [ ] IAP TCP forwarding range (`35.235.240.0/20`) is allowed for SSH access
- [ ] Web ports (80, 443) on origin VMs are restricted to LB ranges only (defense in depth)
- [ ] Explicit deny rules exist for public access to sensitive ports

## Cloud Run / App Engine / Cloud Functions

- [ ] Service runs as a purpose-specific service account, NOT the default
- [ ] Ingress is set to `internal-and-cloud-load-balancing` if the service is fronted by a LB
- [ ] `roles/run.invoker` is granted to `allUsers` ONLY if intentionally public
- [ ] Environment variables do not contain secrets (use Secret Manager mounts instead)
- [ ] Minimum instances is set if cold start is a concern AND the cost is acceptable

## Identity-Aware Proxy (IAP)

For admin and staging endpoints:

- [ ] IAP is enabled on the backend service
- [ ] Specific users/groups are granted `roles/iap.httpsResourceAccessor`, not broad ranges
- [ ] OAuth consent screen is configured with verified contact info
- [ ] IAP authentication failures are monitored (Cloud Logging filter — Filter 8)
- [ ] Bypass paths (e.g., for health checks) are documented and minimal

## Secret Manager

- [ ] All application secrets are stored in Secret Manager (NOT environment variables, NOT in code, NOT in container images)
- [ ] Each secret has IAM bindings scoped to specific accessor service accounts
- [ ] NO project-level `roles/secretmanager.secretAccessor` bindings exist
- [ ] Secret versions are pinned to specific numbers in production deployments (NOT `latest`) OR alias usage is documented
- [ ] Disabled or destroyed secret versions are tracked
- [ ] Secret access events are logged (Data Access logs enabled for `secretmanager.googleapis.com`)

## Cloud Logging

- [ ] `_Default` log bucket retention is 90 days or longer
- [ ] Admin Activity logs are reviewed (Filter 5)
- [ ] Cloud Armor security events are monitored (Filter 1)
- [ ] Data Access logs are enabled for Secret Manager (Filter 7)
- [ ] Log-based metrics exist for high-signal events (Cloud Armor blocks, IAM changes)
- [ ] Cloud Monitoring alert policies notify the on-call channel for critical events
- [ ] Logs export to BigQuery or Cloud Storage is configured if longer retention is needed

## API Surface

- [ ] Only the APIs required for the workload are enabled in the project
- [ ] Disabled APIs are reviewed quarterly — unused APIs should stay disabled
- [ ] `gcloud services list --enabled` output is documented as the current API baseline

## Network Egress (Compute Engine)

- [ ] Egress is reviewed — VMs should have minimum external IPs
- [ ] If VMs need internet egress, consider Cloud NAT instead of public IPs
- [ ] VPC Service Controls perimeters are considered for sensitive data (out of scope for most public web workloads but worth evaluating)

## Backup and Recovery

- [ ] Recovery procedure for the workload is documented
- [ ] Critical data (Cloud SQL databases, persistent disks) has automated backups
- [ ] Backup restore has been tested at least once in a non-production environment
- [ ] Recovery from compromised service account: documented (revoke keys, rotate, audit access)

## Validation

After completing all checks:

- [ ] `audit-gcp-web-project.sh PROJECT_ID` returns no critical issues
- [ ] External scan (e.g., SSL Labs) confirms TLS configuration
- [ ] All Cloud Armor rules show expected match counts in preview/enforcement logs
- [ ] Public site loads, admin paths through IAP work, no legitimate users report issues
- [ ] Next scheduled audit date is recorded

## Documentation

- [ ] Project architecture diagram exists (resources, IAM relationships, network paths)
- [ ] Service account inventory with purpose and granted roles is documented
- [ ] Cloud Armor policy and rules are documented (priority, action, expression, deployment date)
- [ ] Recovery and incident response procedures are documented
