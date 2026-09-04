## Common Failure Cases
- If AWS SSO permissions are required, you can run one of the following commands to refresh them:
    - **Dev:** `aws sso login --profile paradis_dev`
    - **Prod:** `aws sso login --profile paradis_prod`

## Rules
- NEVER commit PHI or HIPAA data to git.
