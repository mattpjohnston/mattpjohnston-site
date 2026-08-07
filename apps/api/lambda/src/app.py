import hashlib
import json
import os
import time
from datetime import datetime, timezone

DEFAULT_SEEN_TTL_SECONDS = 86400 * 2

_table = None


def _utc_now():
    return datetime.now(timezone.utc)


def _get_table():
    # cached so warm invocations skip the boto3 import
    global _table

    if _table is None:
        table_name = os.environ.get("TABLE_NAME")
        if not table_name:
            raise RuntimeError("TABLE_NAME is not set")

        import boto3

        _table = boto3.resource("dynamodb").Table(table_name)

    return _table


def _source_fingerprint(event):
    # only used to dedupe visits within the same day
    request_context = event.get("requestContext") or {}
    source_ip = ((request_context.get("http") or {}).get("sourceIp") or "").strip()
    if source_ip:
        return source_ip

    headers = event.get("headers") or {}
    forwarded = headers.get("x-forwarded-for") or headers.get("X-Forwarded-For") or ""
    if forwarded.strip():
        return forwarded.split(",", 1)[0].strip()

    user_agent = headers.get("user-agent") or headers.get("User-Agent") or ""
    if user_agent.strip():
        return f"ua:{user_agent.strip()}"

    return "unknown"


def _is_already_counted(exc):
    response = getattr(exc, "response", None)
    if not isinstance(response, dict):
        return False

    error = response.get("Error")
    return isinstance(error, dict) and error.get("Code") == "ConditionalCheckFailedException"


def _mark_seen_today(table, fingerprint, now, salt, ttl_seconds):
    # returns False if this fingerprint was already marked today. the salt
    # stops the key being reversed back to an IP, expires_at lets dynamo
    # clear out old markers itself
    day = now.strftime("%Y-%m-%d")
    digest = hashlib.sha256(f"{day}:{fingerprint}:{salt}".encode("utf-8")).hexdigest()

    try:
        table.update_item(
            Key={"pk": f"seen#{day}#{digest}"},
            UpdateExpression="SET expires_at = :ttl",
            ConditionExpression="attribute_not_exists(pk)",
            ExpressionAttributeValues={":ttl": int(now.timestamp()) + ttl_seconds},
        )
        return True
    except Exception as exc:
        if _is_already_counted(exc):
            return False
        raise


def handler(event, context):
    started = time.time()

    try:
        table = _get_table()
        counter_pk = os.environ.get("COUNTER_PK", "site")
        now = _utc_now()

        seen_started = time.time()
        first_visit_today = _mark_seen_today(
            table,
            _source_fingerprint(event if isinstance(event, dict) else {}),
            now,
            os.environ.get("COUNTER_IP_SALT", ""),
            int(os.environ.get("SEEN_TTL_SECONDS", DEFAULT_SEEN_TTL_SECONDS)),
        )
        seen_ms = int((time.time() - seen_started) * 1000)

        if first_visit_today:
            updated = table.update_item(
                Key={"pk": counter_pk},
                UpdateExpression="ADD visits :inc",
                ExpressionAttributeValues={":inc": 1},
                ReturnValues="UPDATED_NEW",
            )
            count = int(updated["Attributes"]["visits"])
        else:
            item = table.get_item(Key={"pk": counter_pk}).get("Item") or {}
            count = int(item.get("visits", 0))

        total_ms = int((time.time() - started) * 1000)
        print(f"counter_timing seen_ms={seen_ms} total_ms={total_ms}")

        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"count": count}),
        }
    except Exception as exc:
        total_ms = int((time.time() - started) * 1000)
        print(f"counter_error total_ms={total_ms} error={exc!r}")

        return {
            "statusCode": 500,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"message": "counter error"}),
        }
