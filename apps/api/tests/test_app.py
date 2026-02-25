import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "lambda" / "src"
sys.path.insert(0, str(SRC))

import app


class ConditionalCheckFailed(Exception):
    response = {"Error": {"Code": "ConditionalCheckFailedException"}}


class FakeTable:
    def __init__(self, *, seen_exists: bool = False, counter: int = 0):
        self.seen_exists = seen_exists
        self.counter = counter
        self.get_calls = 0

    def update_item(self, **kwargs):
        pk = kwargs["Key"]["pk"]

        if pk.startswith("seen#"):
            if self.seen_exists:
                raise ConditionalCheckFailed("already counted")
            self.seen_exists = True
            return {}

        if pk == "site":
            self.counter += int(kwargs["ExpressionAttributeValues"][":inc"])
            return {"Attributes": {"visits": self.counter}}

        raise AssertionError(f"Unexpected pk: {pk}")

    def get_item(self, **kwargs):
        self.get_calls += 1
        assert kwargs["Key"] == {"pk": "site"}
        return {"Item": {"visits": self.counter}}


def test_handler_counts_first_visit_for_day(monkeypatch):
    table = FakeTable(counter=41)
    monkeypatch.setenv("TABLE_NAME", "visitor-counter")
    monkeypatch.setenv("COUNTER_PK", "site")
    monkeypatch.setenv("COUNTER_IP_SALT", "test-salt")
    monkeypatch.setenv("SEEN_TTL_SECONDS", "172800")
    monkeypatch.setattr(app, "_get_table", lambda: table)
    monkeypatch.setattr(
        app, "_utc_now", lambda: datetime(2026, 2, 25, 12, 0, 0, tzinfo=timezone.utc)
    )

    result = app.handler({"requestContext": {"http": {"sourceIp": "203.0.113.1"}}}, {})

    assert result["statusCode"] == 200
    assert json.loads(result["body"]) == {"count": 42}
    assert table.get_calls == 0


def test_handler_does_not_increment_duplicate_visit(monkeypatch):
    table = FakeTable(seen_exists=True, counter=42)
    monkeypatch.setenv("TABLE_NAME", "visitor-counter")
    monkeypatch.setenv("COUNTER_PK", "site")
    monkeypatch.setenv("COUNTER_IP_SALT", "test-salt")
    monkeypatch.setenv("SEEN_TTL_SECONDS", "172800")
    monkeypatch.setattr(app, "_get_table", lambda: table)
    monkeypatch.setattr(
        app, "_utc_now", lambda: datetime(2026, 2, 25, 13, 0, 0, tzinfo=timezone.utc)
    )

    result = app.handler({"requestContext": {"http": {"sourceIp": "203.0.113.1"}}}, {})

    assert result["statusCode"] == 200
    assert json.loads(result["body"]) == {"count": 42}
    assert table.get_calls == 1


def test_handler_error_when_table_name_missing(monkeypatch):
    monkeypatch.delenv("TABLE_NAME", raising=False)

    result = app.handler({}, {})

    assert result["statusCode"] == 500
    assert "counter error" in result["body"]
