# API

Backend code for the visitor counter.

## Structure

- `lambda/src/app.py` Lambda handler
- `tests/test_app.py` Unit tests
- `requirements-dev.txt` Local test dependencies

## Run tests

```bash
cd apps/api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
```

## Deployment

Terraform packages the Lambda from:

- `apps/api/lambda/src`
