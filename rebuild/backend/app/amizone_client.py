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
                "User-Agent": session.user_agent or "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124.0 Mobile Safari/537.36",
                "Referer": self.base + "/Home",
            },
            cookies=session.cookies,
        )

    async def get_html(self, path: str) -> str:
        response = await self.client.get(path)
        response.raise_for_status()
        return response.text

    async def close(self):
        await self.client.aclose()
