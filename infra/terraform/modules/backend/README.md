# backend module

Creates and manages the visitor counter backend:

- DynamoDB table (`PAY_PER_REQUEST`) with TTL for dedupe records
- Lambda function (Python) for counter + same-day dedupe
- API Gateway HTTP API (`GET /counter`) with CORS and throttling
- IAM role/policy attachments for Lambda execution and DynamoDB access
