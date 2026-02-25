# mattpjohnston-site

Personal site monorepo.

This repo contains:

- a static frontend built with Astro
- a small serverless API for the visitor counter
- Terraform for AWS infrastructure
- GitHub Actions for frontend and backend deploys

## Local development

### Frontend (`apps/web`)

```bash
cd apps/web
npm ci
npm run dev
```

Useful commands:

- `npm run build` build static output into `dist/`
- `npm run preview` preview production build locally
- `npx astro check` Astro + TypeScript checks

If you want the visitor counter to work locally, set:

```bash
PUBLIC_COUNTER_API_URL=<your-api-url>/counter
```

You can copy `apps/web/.env.example` as a starting point.

### API tests (`apps/api`)

```bash
cd apps/api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
```

## Content editing

- Blog posts: `apps/web/src/blog`
- Project entries: `apps/web/src/projects`
- Collection schema: `apps/web/src/content.config.ts`

Project cards on `/projects` are sorted by the `order` field in frontmatter.

## Infrastructure and deploy

Terraform is under `infra/terraform`. The production stack includes:

- S3 + CloudFront frontend hosting
- ACM certificate (us-east-1 for CloudFront)
- CloudFront Function for pretty URL rewrites
- Lambda + API Gateway + DynamoDB for the visitor counter
- IAM role for GitHub Actions OIDC deploys

Deploy workflows:

- `.github/workflows/deploy-frontend.yml`
- `.github/workflows/deploy-backend.yml`

`deploy-backend.yml` runs API tests and updates Lambda code for the existing visitor-counter function.
Infrastructure changes for backend resources are still applied through Terraform.

Expected GitHub repo variables:

- `AWS_DEPLOY_ROLE_ARN`
- `S3_BUCKET`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `PUBLIC_COUNTER_API_URL`
- `BACKEND_LAMBDA_FUNCTION_NAME`

`PUBLIC_COUNTER_API_URL` should point at the deployed counter endpoint (for example, the Terraform `backend_counter_url` output).
`BACKEND_LAMBDA_FUNCTION_NAME` should match the deployed counter Lambda name (for example, the Terraform `backend_lambda_function_name` output).
