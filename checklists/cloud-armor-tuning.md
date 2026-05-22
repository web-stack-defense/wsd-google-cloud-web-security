# Cloud Armor Tuning Checklist

How to deploy, validate, and tune Cloud Armor security policies without blocking legitimate traffic.

The default failure mode for a new Cloud Armor policy is blocking real users. The defense against that is the `--preview` flag and disciplined log review before promotion.

## Pre-flight

- [ ] Cloud Armor security policy has been created (see `configs/cloud-armor/owasp-policy.txt`)
- [ ] Backend service that will receive the policy is identified
- [ ] You have at minimum `roles/compute.securityAdmin` on the project
- [ ] Cloud Logging is enabled for the project
- [ ] You have 24 to 72 hours of observation time available before promoting rules

## Initial Deployment in Preview Mode

Every new rule must be deployed with `--preview` first. Preview mode logs what would have been blocked without actually blocking.

- [ ] All rules in the policy were created with the `--preview` flag
- [ ] Verify by listing rules and checking the `preview` field:

```bash
gcloud compute security-policies rules list \
  --security-policy=POLICY_NAME \
  --project=PROJECT_ID \
  --format="table(priority,description,action,preview)"
```

- [ ] Every rule shows `preview: True` before proceeding

## Policy Attachment

- [ ] Policy is attached to the correct backend service
- [ ] Verify attachment:

```bash
gcloud compute backend-services describe BACKEND_SERVICE \
  --global \
  --format="value(securityPolicy)" \
  --project=PROJECT_ID
```

- [ ] Result returns the policy URL, not `null`

## Observation Period (24 to 72 hours minimum)

During the observation window, do not promote rules. Let the policy log what it would block.

- [ ] Wait at least 24 hours for low-traffic sites
- [ ] Wait at least 72 hours for sites with weekly traffic patterns
- [ ] Wait through at least one full business cycle (Monday morning peak, end-of-month batch, etc.)

## Log Review

### Total preview match count per rule

```bash
gcloud logging read \
  'resource.type="http_load_balancer"
   jsonPayload.previewSecurityPolicy.outcome="DENY"' \
  --project=PROJECT_ID \
  --limit=1000 \
  --format="value(jsonPayload.previewSecurityPolicy.name)" | sort | uniq -c | sort -rn
```

- [ ] Counts per rule are reviewed
- [ ] Rules matching tens of thousands of requests are checked for false positives FIRST
- [ ] Rules matching small counts (< 100 in 72 hours) are checked but lower priority

### Sample matched requests

For each rule, sample 10 to 20 matched requests to determine whether they look like attacks or legitimate traffic.

```bash
gcloud logging read \
  'resource.type="http_load_balancer"
   jsonPayload.previewSecurityPolicy.name="RULE_NAME"' \
  --project=PROJECT_ID \
  --limit=20 \
  --format=json
```

For each sampled request:

- [ ] Is the User-Agent a real browser, a known good crawler, or an obvious tool?
- [ ] Is the source IP reputable (lookup at AbuseIPDB if uncertain)?
- [ ] Does the URI or request body contain content that looks like an attack payload?
- [ ] Could a legitimate user generate this request?

## Categorize Matches

For each rule, categorize the matched traffic:

| Category | Action |
|---|---|
| All matches look malicious | Promote rule to enforcement |
| Mix of malicious and legitimate (less than 10% legitimate) | Tune rule to exclude legitimate pattern, re-observe |
| Mostly legitimate matches | Lower sensitivity OR add exclusions OR delete the rule |
| Cannot tell | Continue observing, gather more samples |

## Common Tuning Patterns

### Pattern 1 — Lower sensitivity

If a rule is matching at sensitivity 1 but the matches are mostly false positives, the same rule type may work at a lower sensitivity (which means "no sensitivity-1 signatures") with `opt_in_rule_ids` for specific high-confidence signatures.

```bash
gcloud compute security-policies rules update PRIORITY \
  --security-policy=POLICY_NAME \
  --expression="evaluatePreconfiguredWaf('sqli-v422-stable', {'sensitivity': 0, 'opt_in_rule_ids': ['owasp-crs-v042200-id942100-sqli']})" \
  --project=PROJECT_ID
```

### Pattern 2 — Exclude specific signatures

If most of a rule's signatures are good but one or two are noisy, exclude the noisy ones.

```bash
gcloud compute security-policies rules update PRIORITY \
  --security-policy=POLICY_NAME \
  --expression="evaluatePreconfiguredWaf('sqli-v422-stable', {'sensitivity': 1, 'exclude_ids': ['owasp-crs-v042200-id942110-sqli']})" \
  --project=PROJECT_ID
```

### Pattern 3 — Exclude specific paths

If a rule is matching only on a specific endpoint (e.g., a legitimate search endpoint matching SQL injection signatures), scope the rule to exclude that path.

```bash
gcloud compute security-policies rules update PRIORITY \
  --security-policy=POLICY_NAME \
  --expression="evaluatePreconfiguredWaf('sqli-v422-stable', {'sensitivity': 1}) && !request.path.startsWith('/api/search')" \
  --project=PROJECT_ID
```

### Pattern 4 — Allowlist specific IPs

For known good source IPs (internal scanners, monitoring services), add an allow rule at a higher priority (lower number) than the WAF rule.

```bash
gcloud compute security-policies rules create 500 \
  --security-policy=POLICY_NAME \
  --description="Allowlist internal scanner" \
  --src-ip-ranges=203.0.113.42/32 \
  --action=allow \
  --project=PROJECT_ID
```

## Promotion to Enforcement

Once a rule is confirmed to match only malicious traffic:

- [ ] Remove the `--preview` flag from ONE rule at a time
- [ ] Wait 24 hours after each promotion
- [ ] Verify the site continues to function during business hours after promotion
- [ ] Monitor `jsonPayload.enforcedSecurityPolicy.outcome="DENY"` instead of `previewSecurityPolicy`
- [ ] Repeat for the next rule

```bash
gcloud compute security-policies rules update PRIORITY \
  --security-policy=POLICY_NAME \
  --no-preview \
  --project=PROJECT_ID
```

## Promotion Order

Promote in this order to limit blast radius:

1. Rate limit rules first (these have built-in protection — they throttle rather than hard-block)
2. CVE canary rule (matches narrow, well-known patterns)
3. RCE and RFI rules (rarely match legitimate traffic)
4. Protocol attack rule (rarely matches legitimate traffic)
5. Scanner detection rule (User-Agent based, usually clean)
6. LFI rule
7. SQL injection rule (more likely to have false positives — promote later)
8. XSS rule (more likely to have false positives — promote last)

## Recurring Review

Schedule monthly:

- [ ] Review enforced rule match counts — sudden changes indicate either attack escalation or false-positive regression
- [ ] Check for new preconfigured WAF rule versions (Cloud Armor updates the CRS rule set periodically)
- [ ] Verify all rules still have an owner who understands why each rule exists
- [ ] Review rules that have not matched any traffic in 90+ days — confirm they should remain or remove

Schedule quarterly:

- [ ] Full WAF policy export for archival (`gcloud compute security-policies export`)
- [ ] Review rate limit thresholds against current traffic patterns
- [ ] Verify the OWASP CRS version in use is current (`*-v422-stable` was current at last review)

## Documentation

- [ ] Each rule is documented with: priority, name, action, deployment date, last verification date, owner
- [ ] All tuning decisions are documented with the rationale and date
- [ ] Rollback procedure (what to do if a rule blocks production traffic) is documented and tested
