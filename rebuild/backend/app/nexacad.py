import re
from urllib.parse import urljoin

import httpx
from bs4 import BeautifulSoup

from .config import settings


class JsLiteralReader:
    """Small parser for the JS object/array/string/number subset in NexAcad's bundle."""

    def __init__(self, source: str, index: int):
        self.source = source
        self.i = index

    def _space(self):
        while self.i < len(self.source):
            if self.source[self.i].isspace():
                self.i += 1
            elif self.source.startswith("//", self.i):
                end = self.source.find("\n", self.i)
                self.i = len(self.source) if end < 0 else end + 1
            elif self.source.startswith("/*", self.i):
                end = self.source.find("*/", self.i)
                self.i = len(self.source) if end < 0 else end + 2
            else:
                break

    def _string(self):
        quote = self.source[self.i]
        self.i += 1
        out = []
        while self.i < len(self.source):
            ch = self.source[self.i]
            self.i += 1
            if ch == quote:
                return "".join(out)
            if ch == "\\" and self.i < len(self.source):
                esc = self.source[self.i]
                self.i += 1
                out.append({"n": "\n", "r": "\r", "t": "\t"}.get(esc, esc))
            else:
                out.append(ch)
        raise ValueError("Unterminated JS string")

    def _key(self):
        self._space()
        if self.source[self.i] in ("'", '"', chr(96)):
            return self._string()
        start = self.i
        while self.i < len(self.source) and re.match(r"[A-Za-z0-9_$]", self.source[self.i]):
            self.i += 1
        if self.i == start:
            raise ValueError("Expected JS object key")
        return self.source[start:self.i]

    def value(self):
        self._space()
        if self.i >= len(self.source):
            raise ValueError("Unexpected end of JS bundle")
        ch = self.source[self.i]
        if ch in "{[":
            return self._container()
        if ch in ("'", '"', chr(96)):
            return self._string()
        for word, value in (("true", True), ("false", False), ("null", None), ("undefined", None)):
            if self.source.startswith(word, self.i):
                self.i += len(word)
                return value
        start = self.i
        stops = '{}[],:"' + "'" + chr(96)
        while self.i < len(self.source) and self.source[self.i] not in stops:
            self.i += 1
        raw = self.source[start:self.i].strip()
        if not raw:
            raise ValueError("Unexpected JS token")
        try:
            return float(raw) if "." in raw else int(raw)
        except ValueError:
            return raw

    def _container(self):
        opening = self.source[self.i]
        closing = "}" if opening == "{" else "]"
        self.i += 1
        result = {} if opening == "{" else []
        while True:
            self._space()
            if self.i >= len(self.source):
                raise ValueError("Unterminated JS container")
            if self.source[self.i] == closing:
                self.i += 1
                return result
            if self.source[self.i] == ",":
                self.i += 1
                continue
            if opening == "{":
                key = self._key()
                self._space()
                if self.i >= len(self.source) or self.source[self.i] != ":":
                    raise ValueError("Expected colon in JS object")
                self.i += 1
                result[key] = self.value()
            else:
                result.append(self.value())


def parse_catalogue_bundle(script: str) -> list[dict]:
    marker = script.find("EMBEDDED_COURSE_CATALOG")
    if marker < 0:
        return []
    equals = script.find("=", marker)
    brace = script.find("{", equals if equals >= 0 else marker)
    if brace < 0:
        return []
    try:
        catalog = JsLiteralReader(script, brace).value()
    except (ValueError, IndexError):
        return []
    if not isinstance(catalog, dict):
        return []

    resources: list[dict] = []
    seen: set[str] = set()

    def visit(folder: dict, course_code: str, course_name: str):
        folder_code = _as_text(folder.get("code"))
        folder_name = _as_text(folder.get("name"))
        nested_course = folder.get("type") == "college" and bool(folder_code)
        effective_code = folder_code if nested_course else course_code
        effective_name = folder_name if nested_course and folder_name else course_name
        children = folder.get("children")
        if not isinstance(children, list):
            return
        for child in children:
            if not isinstance(child, dict):
                continue
            kind = _as_text(child.get("type"))
            if kind in {"folder", "college"}:
                visit(child, effective_code, effective_name)
                continue
            title = _as_text(child.get("name"))
            drive_id = _as_text(child.get("fileId"))
            drive_url = _as_text(child.get("driveUrl"))
            if not drive_id:
                match = re.search(r"/d/([A-Za-z0-9_-]{10,})|id=([A-Za-z0-9_-]{10,})", drive_url)
                drive_id = (match.group(1) or match.group(2)) if match else ""
            if not title or not (drive_id or drive_url):
                continue
            key = drive_id or f"{effective_code}/{title}"
            if key in seen:
                continue
            seen.add(key)
            preview = _as_text(child.get("previewUrl")) or (
                f"https://drive.google.com/file/d/{drive_id}/preview" if drive_id else drive_url
            )
            download = _as_text(child.get("downloadUrl")) or (
                f"https://drive.google.com/uc?id={drive_id}&export=download" if drive_id else drive_url
            )
            declared_type = _as_text(child.get("fileType"))
            lower = title.lower()
            file_type = declared_type or (
                "PYQ" if any(x in lower for x in ("pyq", "previous year", "question paper"))
                else "Lab" if "lab" in lower
                else "Books" if "book" in lower else "Notes"
            )
            raw_size = _as_text(child.get("size"))
            try:
                size_num = int(raw_size)
                size = f"{size_num / (1024 * 1024):.1f} MB" if size_num >= 1024 * 1024 else f"{round(size_num / 1024)} KB"
            except ValueError:
                size = raw_size
            resources.append({
                "id": f"nexacad-{key}", "subject_code": effective_code or "General",
                "subject_name": effective_name, "title": title, "file_type": file_type,
                "size": size, "preview_url": preview, "download_url": download,
            })

    for code, folder in catalog.items():
        if isinstance(folder, dict):
            visit(folder, str(code), _as_text(folder.get("name")))
    return resources


def _as_text(value) -> str:
    return value if isinstance(value, str) else ""


async def fetch_catalogue(subject_codes: list[str] | None = None) -> list[dict]:
    base = settings.nexacad_base.rstrip("/") + "/"
    async with httpx.AsyncClient(timeout=30, follow_redirects=True) as client:
        page = await client.get(urljoin(base, "pages/resources.html"))
        page.raise_for_status()
        match = re.search(r"""["']([^"']*course_catalog[^"']*\.js)["']""", page.text)
        script_url = urljoin(base, match.group(1)) if match else urljoin(base, "js/course_catalog.4b19e0c4.js")
        response = await client.get(script_url)
        response.raise_for_status()
        resources = parse_catalogue_bundle(response.text)

    wanted = {code.upper().strip() for code in (subject_codes or []) if code.strip()}
    if wanted:
        filtered = [item for item in resources if item["subject_code"].upper() in wanted]
        if filtered:
            resources = filtered
    return resources
