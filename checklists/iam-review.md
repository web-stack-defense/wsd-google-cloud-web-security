# GCP IAM Review Checklist

Quarterly IAM review checklist for a GCP project hosting a web workload. IAM grants accumulate over time — a project that is properly scoped at deployment can drift into over-privilege within months without regular review.

## Pre-flight

- [ ] You have at minimum `roles/iam.securityReviewer` on the project (or higher)
- [ ] The project's purpose and active workloads are documented
- [ ] You have access to the documentation from the most recent IAM review (if any)

## Project-Level Binding Review

Run this command to get the current state:

```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role,bindings.members)" \
  --sort-by=bindings.role
```

For each binding shown:

- [ ] The role is appropriate for the principal (no Editor or Owner unless documented as required)
- [ ] The principal is current (the person is still employed, the service is still in use)
- [ ] The principal type is correct (`user:`, `serviceAccount:`, `group:`)
- [ ] No `allUsers` or `allAuthenticatedUsers` bindings exist at the project level

## Owner and Editor Audit

- [ ] List all principals with `roles/owner` on the project
- [ ] Each Owner is named individually (no `allUsers`, no broad groups)
- [ ] Each Owner is documented as authorized
- [ ] List all principals with `roles/editor` on the project
- [ ] Service accounts with Editor are reviewed — replace with predefined roles where possible

## Service Account Audit

List all service accounts:

```bash
gcloud iam service-accounts list --project=PROJECT_ID
```

For each service account:

- [ ] Has a clear purpose (named descriptively, not `service-account-1`)
- [ ] Is still in active use (not orphaned from a removed workload)
- [ ] Has only the predefined roles it requires
- [ ] No service account keys exist unless absolutely required

Check service account keys:

```bash
for sa in $(gcloud iam service-accounts list \
  --project=PROJECT_ID \
  --format="value(email)"); do
  echo "Keys for ${sa}:"
  gcloud iam service-accounts keys list \
    --iam-account="${sa}" \
    --project=PROJECT_ID
done
```

For each user-managed service account key:

- [ ] Has a clear, documented purpose
- [ ] Is less than 90 days old (rotate quarterly)
- [ ] Is stored in a secret manager or equivalent (not in code, not in chat logs)
- [ ] The principal using the key cannot use Workload Identity instead

## Default Service Accounts

- [ ] Default Compute Engine SA (`PROJECT_NUMBER-compute@developer.gserviceaccount.com`) is disabled OR has Editor removed
- [ ] Default App Engine SA (`PROJECT_ID@appspot.gserviceaccount.com`) is disabled OR has Editor removed
- [ ] If default SAs are in use, the reason is documented

## Scope-Specific Reviews

### Secret Manager

```bash
gcloud secrets list --project=PROJECT_ID
```

For each secret:

- [ ] Has IAM bindings ONLY for the principals that need it
- [ ] No project-level `secretAccessor` bindings exist that include this secret
- [ ] Disabled or rotated secret versions are documented

### Storage Buckets

```bash
gsutil ls -p PROJECT_ID
```

For each bucket:

- [ ] Does not have `allUsers` or `allAuthenticatedUsers` with read access (unless intentionally public)
- [ ] Uniform bucket-level access is enabled (not legacy ACLs)
- [ ] Bucket-level IAM is scoped to specific accessor principals

### Cloud Run / App Engine

For each service:

- [ ] `roles/run.invoker` granted to `allUsers` only on intentionally public services
- [ ] Admin or staging services are behind IAP
- [ ] Service runs as a purpose-specific service account

## Privileged Roles to Watch

These roles are high-value attack targets. Audit each binding individually:

- [ ] `roles/owner` — Project takeover
- [ ] `roles/editor` — Project takeover (slightly less)
- [ ] `roles/iam.securityAdmin` — Can grant any role
- [ ] `roles/iam.serviceAccountAdmin` — Can manage service accounts
- [ ] `roles/iam.serviceAccountTokenCreator` — Can impersonate other SAs
- [ ] `roles/iam.serviceAccountKeyAdmin` — Can create SA keys
- [ ] `roles/iam.workloadIdentityPoolAdmin` — Can configure workload identity
- [ ] `roles/resourcemanager.projectIamAdmin` — Can manage project IAM
- [ ] `roles/cloudkms.admin` — Can manage encryption keys
- [ ] `roles/secretmanager.admin` — Can manage all secrets

## Conditional Bindings

```bash
gcloud projects get-iam-policy PROJECT_ID \
  --format="json" | jq '.bindings[] | select(.condition)'
```

For each conditional binding:

- [ ] The condition expression is documented
- [ ] The condition has not expired (time-based conditions)
- [ ] The condition continues to make sense for the current state

## Asset Inventory Spot Check

Use Cloud Asset Inventory to find all bindings for a specific principal:

```bash
gcloud asset search-all-iam-policies \
  --scope="projects/PROJECT_ID" \
  --query="policy:user:admin@example.com"
```

- [ ] Each former employee or contractor has been removed from all bindings
- [ ] Each external collaborator (non-organization member) has documented justification
- [ ] No principal has roles in places they shouldn't

## Activity Review

```bash
gcloud logging read \
  'protoPayload.methodName=("SetIamPolicy" OR "setIamPolicy")
   timestamp >= "PREVIOUS_REVIEW_DATE"' \
  --project=PROJECT_ID \
  --limit=200 \
  --format="table(timestamp,
                  protoPayload.authenticationInfo.principalEmail,
                  protoPayload.resourceName,
                  protoPayload.methodName)"
```

- [ ] Every IAM change since the last review is reviewed
- [ ] Each change has a documented reason (deployment, new hire, role change)
- [ ] Unexpected changes are investigated

## Service Account Key Activity

```bash
gcloud logging read \
  'protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
   timestamp >= "PREVIOUS_REVIEW_DATE"' \
  --project=PROJECT_ID \
  --limit=50
```

- [ ] Every service account key created since the last review is documented
- [ ] Each key creation has a known purpose
- [ ] Keys created for one-off tasks have been deleted

## Output

After completing the review:

- [ ] Inventory of current bindings is saved (export `get-iam-policy` output)
- [ ] Changes made during the review are documented (what was removed and why)
- [ ] Next review date is scheduled (90 days)
- [ ] Open follow-up items are tracked (e.g., "switch SA X from key to Workload Identity by date Y")
