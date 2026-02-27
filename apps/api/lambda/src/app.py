import hashlib
import json
import os
import time
from datetime import datetime, timezone

SECONDS_PER_DAY = 86400
DEFAULT_SEEN_TTL_SECONDS = SECONDS_PER_DAY * 2
_TABLE = None


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _get_table():
    global _TABLE
    if _TABLE is not None:
        return _TABLE

    table_name = os.environ.get("TABLE_NAME")
    if not table_name:
        raise RuntimeError("TABLE_NAME is not set")

    import boto3

    _TABLE = boto3.resource("dynamodb").Table(table_name)
    return _TABLE


def _extract_source_fingerprint(event: object) -> str:
    if not isinstance(event, dict):
        return "unknown"

    request_context = event.get("requestContext", {})
    if isinstance(request_context, dict):
        http_context = request_context.get("http", {})
        if isinstance(http_context, dict):
            source_ip = http_context.get("sourceIp")
            if isinstance(source_ip, str) and source_ip.strip():
                return source_ip.strip()

    headers = event.get("headers", {})
    if isinstance(headers, dict):
        forwarded_for = headers.get("x-forwarded-for") or headers.get("X-Forwarded-For")
        if isinstance(forwarded_for, str) and forwarded_for.strip():
            return forwarded_for.split(",", 1)[0].strip()

        user_agent = headers.get("user-agent") or headers.get("User-Agent")
        if isinstance(user_agent, str) and user_agent.strip():
            return f"ua:{user_agent.strip()}"

    return "unknown"


def _seen_key(source_fingerprint: str, now_utc: datetime, salt: str) -> str:
    day = now_utc.strftime("%Y-%m-%d")
    digest = hashlib.sha256(
        f"{day}:{source_fingerprint}:{salt}".encode("utf-8")
    ).hexdigest()
    return f"seen#{day}#{digest}"


def _is_conditional_check_failed(exc: Exception) -> bool:
    response = getattr(exc, "response", None)
    if not isinstance(response, dict):
        return False

    error = response.get("Error", {})
    if not isinstance(error, dict):
        return False

    return error.get("Code") == "ConditionalCheckFailedException"


def _mark_seen_for_day(
    table, source_fingerprint: str, now_utc: datetime, salt: str, ttl_seconds: int
) -> bool:
    seen_pk = _seen_key(source_fingerprint, now_utc, salt)
    expires_at = int(now_utc.timestamp()) + ttl_seconds

    try:
        table.update_item(
            Key={"pk": seen_pk},
            UpdateExpression="SET expires_at = :ttl",
            ConditionExpression="attribute_not_exists(pk)",
            ExpressionAttributeValues={":ttl": expires_at},
        )
        return True
    except Exception as exc:
        if _is_conditional_check_failed(exc):
            return False
        raise


def _increment_counter(table, counter_pk: str) -> int:
    response = table.update_item(
        Key={"pk": counter_pk},
        UpdateExpression="ADD visits :inc",
        ExpressionAttributeValues={":inc": 1},
        ReturnValues="UPDATED_NEW",
    )
    return int(response["Attributes"]["visits"])


def _read_counter(table, counter_pk: str) -> int:
    response = table.get_item(Key={"pk": counter_pk})
    item = response.get("Item", {}) if isinstance(response, dict) else {}
    visits = item.get("visits", 0) if isinstance(item, dict) else 0
    return int(visits)


def handler(event, context):
    started = time.time()
    try:
        table = _get_table()
        counter_pk = os.environ.get("COUNTER_PK", "site")
        now_utc = _utc_now()
        source_fingerprint = _extract_source_fingerprint(event)
        salt = os.environ.get("COUNTER_IP_SALT", "")
        seen_ttl_seconds = int(
            os.environ.get("SEEN_TTL_SECONDS", str(DEFAULT_SEEN_TTL_SECONDS))
        )

        seen_started = time.time()
        is_new_for_day = _mark_seen_for_day(
            table=table,
            source_fingerprint=source_fingerprint,
            now_utc=now_utc,
            salt=salt,
            ttl_seconds=seen_ttl_seconds,
        )
        seen_ms = int((time.time() - seen_started) * 1000)

        counter_started = time.time()
        count = (
            _increment_counter(table, counter_pk)
            if is_new_for_day
            else _read_counter(table, counter_pk)
        )
        counter_ms = int((time.time() - counter_started) * 1000)
        total_ms = int((time.time() - started) * 1000)
        print(
            f"counter_timing seen_ms={seen_ms} counter_ms={counter_ms} total_ms={total_ms}"
        )

        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"count": count}),
        }
    except Exception as exc:
        total_ms = int((time.time() - started) * 1000)
        print(f"counter_error total_ms={total_ms} error={exc}")
        return {
            "statusCode": 500,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"message": "counter error", "error": str(exc)}),
        }
