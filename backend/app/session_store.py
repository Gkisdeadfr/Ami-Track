from dataclasses import dataclass
from datetime import datetime
from .security import token_digest

@dataclass
class PortalSession:
    username: str
    cookies: dict[str, str]
    user_agent: str | None
    expires_at: datetime

class SessionStore:
    """Single-process development store. Replace with encrypted Redis/Postgres in production."""
    def __init__(self) -> None:
        self._sessions: dict[str, PortalSession] = {}

    def put(self, token: str, session: PortalSession) -> None:
        self._sessions[token_digest(token)] = session

    def get(self, token: str) -> PortalSession | None:
        key = token_digest(token)
        value = self._sessions.get(key)
        if value and value.expires_at <= __import__("datetime").datetime.now(__import__("datetime").timezone.utc):
            self._sessions.pop(key, None)
            return None
        return value

    def delete(self, token: str) -> None:
        self._sessions.pop(token_digest(token), None)

sessions = SessionStore()
