# Terraform layout

```text
infra/terraform/
  modules/
    frontend/
    backend/
  environments/
    prod/
```

Terraform needs credentials in the environment. If the CLI is signed in with
`aws login` the provider won't see it, so bridge them first:

```bash
. <(aws configure export-credentials --format env)
```

## Frontend deploy flow (Cloudflare DNS)

1. `cd infra/terraform/environments/prod`
2. `terraform init`
3. `terraform apply` with defaults (`validate_certificate=false`, `create_distribution=false`) to create S3 + ACM request.
4. `terraform output acm_validation_records`
5. Add returned CNAME records in Cloudflare (DNS only).
6. Set `validate_certificate=true` in `terraform.tfvars`.
7. `terraform apply`
8. Set `create_distribution=true` in `terraform.tfvars`.
9. `terraform apply`
10. `terraform output distribution_domain_name`
11. In Cloudflare DNS, point apex and `www` CNAME to distribution domain (DNS only).

## Upload site

From `apps/web`:

1. `npm run build`
2. `aws s3 sync dist/ s3://<bucket_name> --delete --exclude "*" --include "_astro/*" --cache-control "public,max-age=31536000,immutable"`
3. `aws s3 sync dist/ s3://<bucket_name> --delete --exclude "_astro/*" --cache-control "public,max-age=0,must-revalidate"`
4. `aws cloudfront create-invalidation --distribution-id <distribution_id> --paths "/*"`

Only the `_astro` files get the long cache, they have a hash in the filename.

## CI variables

From `infra/terraform/environments/prod`:

1. `terraform apply`
2. `terraform output github_repository_variables`

In GitHub repository settings, create repository variables:

- `AWS_DEPLOY_ROLE_ARN`
- `S3_BUCKET`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `PUBLIC_COUNTER_API_URL`
- `BACKEND_LAMBDA_FUNCTION_NAME`

Workflow files:

- `.github/workflows/deploy-frontend.yml`
- `.github/workflows/deploy-backend.yml`

`deploy-backend.yml` deploys Lambda code updates. Backend infrastructure changes still require Terraform apply.
