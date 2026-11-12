from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import secrets

from .config import settings

def issue_token() -> tuple[str, datetime]:
    token = secrets.token_urlsafe(40)
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.session_ttl_minutes)
    return token, expires

def token_digest(token: str) -> str:
    return hmac.new(settings.token_secret.encode(), token.encode(), hashlib.sha256).hexdigest()
