# Security Policy

This repository contains Google Cloud security references intended for use in defensive web security work.

## Reporting Security Issues in This Repository

If you find a security issue in any gcloud command, configuration, or guide in this repository that could cause harm if applied as written, please report it privately.

**Do not file public GitHub issues for security problems in the content itself.**

To report a security issue:

- Open a private security advisory through GitHub's security advisory feature
- Or contact Web Stack Defense through [webstackdefense.com](https://www.webstackdefense.com)

Reports should include:

- The file or section affected
- A description of the issue
- The conditions under which the issue would cause harm
- Suggested remediation if known

## Reporting Google Cloud Product Vulnerabilities

This repository is not the correct venue for reporting Google Cloud product vulnerabilities. Those should be reported directly to Google:

- Google Vulnerability Reward Program: [https://bughunters.google.com/](https://bughunters.google.com/)
- Google Cloud security contact: [https://cloud.google.com/support/docs/issue-trackers](https://cloud.google.com/support/docs/issue-trackers)

## Disclaimer

All content in this repository is provided for reference. Test all commands in a non-production GCP project before applying to production. The maintainers accept no liability for outcomes from applying any content here.

GCP resources have real billing impact. Cloud Armor rules in enforcement mode can block legitimate traffic. IAM changes can lock out admins. Firewall rules can take a site offline. Every example in this repository has a documented validation path — follow it.
