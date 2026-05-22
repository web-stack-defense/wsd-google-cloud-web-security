#!/usr/bin/env bash
# =============================================================================
# GCP Web Project Security Audit
#
# Repository: wsd-google-cloud-web-security
# Maintained as part of Web Stack Defense — https://www.webstackdefense.com
#
# Read-only audit script. Does not modify any GCP resource.
#
# Audits a Google Cloud project for common web workload security
# misconfigurations:
#
#   - Service accounts with broad project roles (Owner, Editor)
#   - Firewall rules that allow 0.0.0.0/0 to sensitive ports
#   - Cloud Armor policies in preview mode
#   - SSL policies on target HTTPS proxies
#   - Public Cloud Run services
#   - Default service accounts still in use
#
# Usage:
#   ./audit-gcp-web-project.sh PROJECT_ID
#
# Requirements:
#   - gcloud CLI installed and authenticated
#   - Reader-level permissions on the target project
#   - Bash 4.0+
#   - jq (optional, used for cleaner output)
# =============================================================================

set -euo pipefail


# -----------------------------------------------------------------------------
# Argument handling
# -----------------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 PROJECT_ID" >&2
    exit 2
fi

PROJECT_ID="$1"


# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------

if ! command -v gcloud &>/dev/null; then
    echo "Error: gcloud CLI is not installed." >&2
    exit 1
fi

# Verify we can read the project.
if ! gcloud projects describe "${PROJECT_ID}" &>/dev/null; then
    echo "Error: cannot describe project '${PROJECT_ID}'. Check that the project exists and you have access." >&2
    exit 1
fi


# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------

ISSUES=0

report_section() {
    echo ""
    echo "=============================================================="
    echo "  $1"
    echo "=============================================================="
}

report_ok() {
    echo "  [OK]    $1"
}

report_issue() {
    echo "  [ISSUE] $1"
    ISSUES=$((ISSUES + 1))
}

report_info() {
    echo "  [INFO]  $1"
}


# -----------------------------------------------------------------------------
# Check 1: Owner and Editor role bindings
# -----------------------------------------------------------------------------

report_section "Project IAM — Owner and Editor bindings"

BROAD_BINDINGS=$(gcloud projects get-iam-policy "${PROJECT_ID}" \
    --flatten="bindings[].members" \
    --filter="bindings.role:(roles/owner OR roles/editor)" \
    --format="value(bindings.role,bindings.members)" 2>/dev/null || echo "")

if [[ -z "${BROAD_BINDINGS}" ]]; then
    report_ok "No Owner or Editor bindings found (very strict — verify expected)"
else
    while IFS=$'\t' read -r role member; do
        if [[ -n "${role}" ]]; then
            if [[ "${member}" == "serviceAccount:"* ]]; then
                report_issue "${role} granted to service account: ${member}"
            else
                report_info "${role} granted to: ${member}"
            fi
        fi
    done <<< "${BROAD_BINDINGS}"
fi


# -----------------------------------------------------------------------------
# Check 2: Firewall rules allowing 0.0.0.0/0 to sensitive ports
# -----------------------------------------------------------------------------

report_section "Firewall — public ingress to sensitive ports"

SENSITIVE_RULES=$(gcloud compute firewall-rules list \
    --project="${PROJECT_ID}" \
    --filter="sourceRanges:0.0.0.0/0 AND direction=INGRESS AND disabled=false" \
    --format="value(name,allowed[].ports.list())" 2>/dev/null || echo "")

if [[ -z "${SENSITIVE_RULES}" ]]; then
    report_ok "No firewall rules allow 0.0.0.0/0 ingress"
else
    while IFS=$'\t' read -r name ports; do
        if [[ -z "${name}" ]]; then
            continue
        fi
        # Flag SSH (22), RDP (3389), and database ports specifically.
        if echo "${ports}" | grep -qE "(^|;)(22|3389|3306|5432|6379|27017|9200)(;|$)"; then
            report_issue "${name} allows 0.0.0.0/0 to sensitive port(s): ${ports}"
        elif echo "${ports}" | grep -qE "(^|;)(80|443)(;|$)"; then
            report_info "${name} allows 0.0.0.0/0 to web port(s) ${ports} — expected if no LB in front"
        else
            report_info "${name} allows 0.0.0.0/0 to: ${ports}"
        fi
    done <<< "${SENSITIVE_RULES}"
fi


# -----------------------------------------------------------------------------
# Check 3: Cloud Armor policies and rules
# -----------------------------------------------------------------------------

report_section "Cloud Armor — security policies"

POLICIES=$(gcloud compute security-policies list \
    --project="${PROJECT_ID}" \
    --format="value(name)" 2>/dev/null || echo "")

if [[ -z "${POLICIES}" ]]; then
    report_issue "No Cloud Armor security policies found in project"
else
    for policy in ${POLICIES}; do
        report_info "Policy: ${policy}"

        # Count rules in preview mode.
        PREVIEW_COUNT=$(gcloud compute security-policies rules list \
            --security-policy="${policy}" \
            --project="${PROJECT_ID}" \
            --filter="preview=true" \
            --format="value(priority)" 2>/dev/null | wc -l)

        if [[ "${PREVIEW_COUNT}" -gt 0 ]]; then
            report_info "  ${PREVIEW_COUNT} rule(s) in preview mode (review and promote)"
        fi
    done
fi


# -----------------------------------------------------------------------------
# Check 4: SSL policies on target HTTPS proxies
# -----------------------------------------------------------------------------

report_section "Load balancers — SSL policies"

PROXIES=$(gcloud compute target-https-proxies list \
    --project="${PROJECT_ID}" \
    --format="value(name,sslPolicy)" 2>/dev/null || echo "")

if [[ -z "${PROXIES}" ]]; then
    report_info "No target HTTPS proxies found in project"
else
    while IFS=$'\t' read -r proxy_name ssl_policy; do
        if [[ -z "${proxy_name}" ]]; then
            continue
        fi
        if [[ -z "${ssl_policy}" ]] || [[ "${ssl_policy}" == "null" ]]; then
            report_issue "${proxy_name} has NO SSL policy attached (uses GCP default)"
        else
            POLICY_NAME=$(basename "${ssl_policy}")
            report_ok "${proxy_name} has SSL policy: ${POLICY_NAME}"
        fi
    done <<< "${PROXIES}"
fi


# -----------------------------------------------------------------------------
# Check 5: Backend services without Cloud Armor
# -----------------------------------------------------------------------------

report_section "Backend services — Cloud Armor attachment"

BACKENDS=$(gcloud compute backend-services list \
    --project="${PROJECT_ID}" \
    --format="value(name,securityPolicy)" 2>/dev/null || echo "")

if [[ -z "${BACKENDS}" ]]; then
    report_info "No backend services found in project"
else
    while IFS=$'\t' read -r backend_name security_policy; do
        if [[ -z "${backend_name}" ]]; then
            continue
        fi
        if [[ -z "${security_policy}" ]] || [[ "${security_policy}" == "null" ]]; then
            report_issue "${backend_name} has NO Cloud Armor policy attached"
        else
            POLICY_NAME=$(basename "${security_policy}")
            report_ok "${backend_name} has Cloud Armor: ${POLICY_NAME}"
        fi
    done <<< "${BACKENDS}"
fi


# -----------------------------------------------------------------------------
# Check 6: Public Cloud Run services
# -----------------------------------------------------------------------------

report_section "Cloud Run — services accessible to allUsers"

# Cloud Run services are regional; iterate over likely regions or
# accept the gcloud default region.
SERVICES=$(gcloud run services list \
    --project="${PROJECT_ID}" \
    --platform=managed \
    --format="value(metadata.name,metadata.namespace)" 2>/dev/null || echo "")

if [[ -z "${SERVICES}" ]]; then
    report_info "No Cloud Run services found (or none in default region)"
else
    while IFS=$'\t' read -r svc_name svc_namespace; do
        if [[ -z "${svc_name}" ]]; then
            continue
        fi
        # Check if allUsers has roles/run.invoker.
        POLICY=$(gcloud run services get-iam-policy "${svc_name}" \
            --project="${PROJECT_ID}" \
            --format="value(bindings.members)" 2>/dev/null || echo "")
        if echo "${POLICY}" | grep -q "allUsers"; then
            report_info "${svc_name} is publicly accessible (allUsers can invoke) — verify intended"
        else
            report_ok "${svc_name} is not publicly accessible"
        fi
    done <<< "${SERVICES}"
fi


# -----------------------------------------------------------------------------
# Check 7: Default service accounts
# -----------------------------------------------------------------------------

report_section "Service accounts — default service accounts"

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" \
    --format="value(projectNumber)" 2>/dev/null || echo "")

if [[ -n "${PROJECT_NUMBER}" ]]; then
    DEFAULT_COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
    DEFAULT_APPENGINE_SA="${PROJECT_ID}@appspot.gserviceaccount.com"

    for default_sa in "${DEFAULT_COMPUTE_SA}" "${DEFAULT_APPENGINE_SA}"; do
        STATE=$(gcloud iam service-accounts describe "${default_sa}" \
            --project="${PROJECT_ID}" \
            --format="value(disabled)" 2>/dev/null || echo "missing")

        if [[ "${STATE}" == "missing" ]]; then
            report_ok "Default SA ${default_sa} does not exist"
        elif [[ "${STATE}" == "True" ]]; then
            report_ok "Default SA ${default_sa} is disabled"
        else
            report_info "Default SA ${default_sa} is enabled — verify it is needed"
        fi
    done
fi


# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

report_section "Summary"

if [[ "${ISSUES}" -eq 0 ]]; then
    echo "  No issues found."
    echo ""
    echo "  Note: this script does not check every possible misconfiguration."
    echo "  Review the checklists in this repository for a comprehensive audit."
    exit 0
else
    echo "  ${ISSUES} issue(s) found. Review above for details."
    exit 1
fi
