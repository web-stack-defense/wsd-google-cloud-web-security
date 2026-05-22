# Tested Environment

The content in this repository was shaped against the following Google Cloud environments and product versions.

## Google Cloud Products

- **Cloud Armor**: External global and regional security policies
- **Cloud Armor preconfigured WAF rules**: OWASP CRS 4.22 (current stable)
- **External Application Load Balancer**: Global and regional variants
- **Cloud Run**: 2nd generation execution environment
- **Compute Engine**: e2 and n2 instance families
- **Cloud Logging**: Project-scoped log buckets with structured logs
- **Secret Manager**: Global and regional secrets
- **Cloud CDN**: With cache key policies
- **Identity-Aware Proxy (IAP)**: For admin and staging endpoints
- **Cloud Monitoring**: Alerting policies for security events

## gcloud CLI

- gcloud CLI version 500.x.x and newer
- Components: `core`, `gke-gcloud-auth-plugin`, `gsutil`

Verify your version with:

```bash
gcloud --version
```

If your gcloud CLI is older than version 450.0.0, several Cloud Armor commands referenced in this repository may use different flag names or unsupported expression syntax. Update before applying.

## OWASP Core Rule Set

- OWASP Core Rule Set version 4.22 (Cloud Armor naming: `*-v422-stable`)
- Signature ID format: `owasp-crs-v042200-idNNNNNN-{category}`

The Cloud Armor expressions in this repository use the `-v422-stable` rule names. The older `-v33-stable` (CRS 3.3) and `-v3-stable` (CRS 3.0) names are deprecated. If you copy expressions from older guides into modern policies, update the rule names.

Reference: [Cloud Armor preconfigured WAF rules](https://cloud.google.com/armor/docs/waf-rules)

## IAM Roles Referenced

This repository references predefined roles by their exact role IDs:

- `roles/run.invoker`
- `roles/run.developer`
- `roles/logging.logWriter`
- `roles/logging.viewer`
- `roles/logging.configWriter`
- `roles/secretmanager.secretAccessor`
- `roles/secretmanager.admin`
- `roles/compute.securityAdmin`
- `roles/compute.networkAdmin`
- `roles/iap.httpsResourceAccessor`
- `roles/monitoring.viewer`
- `roles/monitoring.alertPolicyEditor`

Custom roles are not used in this baseline content. Custom roles add maintenance overhead and are appropriate only when no predefined role fits.

Reference: [IAM predefined roles](https://cloud.google.com/iam/docs/understanding-roles)

## SSL Policy Profiles

Cloud HTTPS Load Balancer SSL policies use Google-managed profiles:

- `COMPATIBLE` — Broadest compatibility, supports older clients
- `MODERN` — Modern profile, TLS 1.0 to 1.2 negotiable
- `RESTRICTED` — Strictest profile, TLS 1.2+ only, AEAD ciphers only

Examples in this repository use `RESTRICTED` as the recommended default for new deployments. Reference: [SSL policies](https://cloud.google.com/load-balancing/docs/use-ssl-policies)

## Notes on Compatibility

- Cloud Armor preconfigured WAF rules can inspect up to 64 KB of the request body. Larger payloads are not inspected.
- IAM changes take 2 to 7 minutes to propagate. Test grants after this delay, not immediately.
- Service accounts created automatically by Google services (default Compute Engine, Cloud Run, etc.) have wide default permissions. Replace with custom service accounts before production deployment.
- Cloud Logging retention defaults to 30 days for `_Default` buckets. Configure custom retention if longer history is required.
- IAP requires HTTPS load balancing. It cannot be used directly with Cloud Run unless the service is fronted by a load balancer.

## Last Verified

The Cloud Armor preconfigured rule names, gcloud command syntax, and IAM role IDs in this repository were verified against current Google Cloud documentation at the time of the most recent commit. Update this file when the content is reviewed against current docs.
