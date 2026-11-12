from bs4 import BeautifulSoup
import re
from urllib.parse import urljoin

CODE = re.compile(r"\b[A-Z]{2,6}\d{2,5}[A-Z]?\b")
RATIO = re.compile(r"(\d+)\s*/\s*(\d+)")

def is_login_page(markup: str) -> bool:
    if not markup.strip():
        return True
    soup = BeautifulSoup(markup, "html.parser")
    return soup.select_one("#loginform, input[name='_Password']") is not None

def _clean(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()

def parse_attendance_page(markup: str) -> list[dict]:
    """Parse only rows belonging to the My Attendance widget."""
    if is_login_page(markup):
        return []
    soup = BeautifulSoup(markup, "html.parser")
    scope = None
    selectors = ".widget-header, .widget-title, h4, h5, h6, .card-title, .panel-title"
    for heading in soup.select(selectors):
        title = _clean(heading.get_text(" ", strip=True)).lower()
        if "attendance" not in title or "exam" in title or "summary" in title:
            continue
        node = heading.parent
        for _ in range(5):
            if node is None:
                break
            classes = " ".join(node.get("class", [])).lower()
            if any(x in classes for x in ("widget-box", "widget-container-col", "panel", "card")) or node.select_one("#tasks, ul.item-list"):
                scope = node
                break
            node = node.parent
        if scope:
            break
    if scope is None:
        scope = soup.select_one("#tasks")
        if scope is None:
            return []

    rows = scope.select("#tasks li, ul.item-list li, ul.list-unstyled li, li.clearfix, li[class*='item-']")
    if scope.name == "ul":
        rows = scope.select("li")
    output, seen = [], set()
    for row in rows:
        label = _clean((row.select_one(".lbl, .subject-title, label") or row).get_text(" ", strip=True))
        code_node = row.select_one(".sub-code, [class*='code']")
        code = _clean(code_node.get_text(" ", strip=True)) if code_node else ""
        match = CODE.search(label)
        code = (code or (match.group(0) if match else "")).upper()
        if not code or code in seen:
            continue
        ratio_node = row.select_one(".class-count, [class*='count']")
        ratio_match = RATIO.search(ratio_node.get_text(" ", strip=True) if ratio_node else "")
        if not ratio_match:
            ratio_match = RATIO.search(row.get_text(" ", strip=True))
        if ratio_match:
            attended, held = map(int, ratio_match.groups())
        else:
            percent = re.search(r"(\d+(?:\.\d+)?)\s*%", row.get_text(" ", strip=True))
            if not percent:
                continue
            attended, held = round(float(percent.group(1))), 100
        if held < 0 or attended < 0 or attended > held:
            continue
        name = re.sub(re.escape(code), "", label, flags=re.I)
        name = RATIO.sub("", name)
        name = re.sub(r"\d+(?:\.\d+)?\s*%", "", name).strip(" -:|")
        output.append({"id": code, "subject_code": code, "subject_name": name or code,
                       "attended": attended, "held": held,
                       "percentage": round(attended / held * 100, 2) if held else 100.0})
        seen.add(code)
    return output

def parse_course_list_page(markup: str) -> list[dict]:
    if is_login_page(markup):
        return []
    soup = BeautifulSoup(markup, "html.parser")
    output, seen = [], set()
    for row in soup.select("tr"):
        cells = row.select("td")
        if not cells:
            continue
        code, name, kind, internal = "", "", "Compulsory", ""
        for cell in cells:
            key = (cell.get("data-title") or cell.get("data-original-title") or "").lower()
            val = _clean(cell.get_text(" ", strip=True))
            if "code" in key and not code:
                code = val
            elif any(k in key for k in ("name", "title", "subject")) and not name:
                name = val
            elif "type" in key:
                kind = val or kind
            elif "internal" in key or "asses" in key:
                internal = val
        if not code:
            for i, cell in enumerate(cells):
                val = _clean(cell.get_text(" ", strip=True))
                if re.fullmatch(r"[A-Z]{2,6}\d{2,5}[A-Z]?", val):
                    code = val
                    if i + 1 < len(cells):
                        name = _clean(cells[i + 1].get_text(" ", strip=True))
                    break
        code = code.upper()
        if not code or code in seen:
            continue
        marks = re.search(r"(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)", internal)
        output.append({"id": code, "subject_code": code, "subject_name": name or code,
                       "attended": 0, "held": 0, "percentage": 0,
                       "internal_marks": float(marks.group(1)) if marks else 0,
                       "max_internal": float(marks.group(2)) if marks else 40,
                       "course_type": kind, "credits": 4})
        seen.add(code)
    return output

def parse_profile(markup: str, base_url: str) -> dict:
    if is_login_page(markup):
        return {}
    soup = BeautifulSoup(markup, "html.parser")
    name, enrollment, photo = "", "", ""
    user = soup.select_one(".user-info, [class*='user-info']")
    if user:
        small = user.select_one("small")
        if small:
            enrollment = _clean(small.get_text(" ", strip=True))
            name = _clean(user.get_text(" ", strip=True).replace(small.get_text(" ", strip=True), ""))
        else:
            text = _clean(user.get_text(" ", strip=True))
            match = re.search(r"\b[A-Za-z]\d{9,12}\b|\b\d{7,10}\b", text)
            if match:
                enrollment = match.group(0)
                name = _clean(text.replace(enrollment, ""))
            else:
                name = text
    image = soup.select_one(".nav-user-photo, img[src*='ImageViewer'], #userphoto img")
    if image:
        photo = urljoin(base_url, image.get("src", ""))
    return {"name": name, "enrollment_number": enrollment, "profile_picture_url": photo}
