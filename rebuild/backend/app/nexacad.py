import re
import httpx
from bs4 import BeautifulSoup
from .config import settings

async def fetch_catalogue(subject_codes: list[str] | None = None) -> list[dict]:
    base = settings.nexacad_base.rstrip("/")
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        response = await client.get(base + "/pages/resources.html")
        response.raise_for_status()
        soup = BeautifulSoup(response.text, "html.parser")
        resources = []
        for anchor in soup.select("a[href]"):
            href = anchor.get("href", "")
            title = " ".join(anchor.get_text(" ", strip=True).split()) or anchor.get("title", "")
            if not title or not ("drive.google.com" in href or href.lower().endswith((".pdf", ".ppt", ".pptx", ".doc", ".docx"))):
                continue
            url = httpx.URL(href, base=base)
            code = ""
            match = re.search(r"\b[A-Z]{2,6}\d{2,5}[A-Z]?\b", title)
            if match:
                code = match.group(0)
            if subject_codes and code and code not in set(subject_codes):
                continue
            resources.append({"id": str(url), "subject_code": code or "General",
                              "subject_name": "", "title": title, "file_type": "Notes",
                              "size": "", "preview_url": str(url), "download_url": str(url)})
        return resources
