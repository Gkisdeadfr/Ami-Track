import httpx

from .config import settings
from .session_store import PortalSession


class AmizoneClient:
    def __init__(self, session: PortalSession):
        self.session = session
        self.base = settings.portal_base.rstrip("/")
        self.client = httpx.AsyncClient(
            base_url=self.base,
            timeout=httpx.Timeout(25.0),
            follow_redirects=True,
            headers={
                "User-Agent": session.user_agent or (
                    "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 "
                    "Chrome/124.0 Mobile Safari/537.36"
                ),
                "Accept": "text/html,application/xhtml+xml",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": self.base + "/Home",
            },
            cookies=session.cookies,
        )

    async def get_html(self, path: str) -> str:
        response = await self.client.get(path)
        response.raise_for_status()
        return response.text

    async def post_html(self, path: str, form: dict[str, str]) -> str:
        response = await self.client.post(
            path,
            data=form,
            headers={
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "X-Requested-With": "XMLHttpRequest",
            },
        )
        response.raise_for_status()
        return response.text

    async def close(self):
        # Preserve any cookies rotated by Amizone during this request batch.
        self.session.cookies = dict(self.client.cookies)
        await self.client.aclose()
