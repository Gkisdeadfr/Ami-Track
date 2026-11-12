from bs4 import BeautifulSoup
from datetime import datetime
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


def _internal_marks(raw: str) -> tuple[float, float]:
    match = re.search(r"(\d+(?:\.\d+)?)(?:\[[^\]]*\])?\s*/\s*(\d+(?:\.\d+)?)", raw or "")
    if not match:
        return 0.0, 40.0
    return float(match.group(1)), float(match.group(2))


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
        output.append({"id": code.lower(), "subject_code": code, "subject_name": name or code,
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
        code, name, kind, internal, attendance = "", "", "Compulsory", "", ""
        for cell in cells:
            key = (cell.get("data-title") or cell.get("data-original-title") or "").lower()
            val = _clean(cell.get_text(" ", strip=True))
            if "code" in key and not code:
                code = val
            elif any(k in key for k in ("name", "title", "subject")) and not name:
                name = val
            elif "type" in key:
                kind = val or kind
            elif "attendance" in key:
                attendance = val
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
        ratio = RATIO.search(attendance)
        attended, held = map(int, ratio.groups()) if ratio else (0, 0)
        marks, maximum = _internal_marks(internal)
        output.append({"id": code.lower(), "subject_code": code, "subject_name": name or code,
                       "attended": attended, "held": held,
                       "percentage": round(attended / held * 100, 2) if held else 0,
                       "internal_marks": marks, "max_internal": maximum,
                       "course_type": kind, "credits": 4})
        seen.add(code)
    return output


def parse_available_semesters(markup: str) -> list[str]:
    soup = BeautifulSoup(markup, "html.parser")
    select = soup.select_one("#CurrentSemesterInfo, select[name*='Semester'], select[id*='Semester']")
    if not select:
        return []
    options = []
    for option in select.select("option"):
        value = (option.get("value") or "").strip()
        if value.isdigit():
            if option.has_attr("selected"):
                options.insert(0, value)
            else:
                options.append(value)
    return options


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
    name = re.sub(r"^(Mr|Ms|Mrs|Dr|Prof)\.?\s+", "", name, flags=re.I)
    image = soup.select_one(".nav-user-photo, img[src*='ImageViewer'], #userphoto img")
    if image:
        photo = urljoin(base_url, image.get("src", ""))
    return {"name": name, "enrollment_number": enrollment, "profile_picture_url": photo}


def parse_profile_id_card(markup: str, base_url: str) -> dict:
    if is_login_page(markup):
        return {}
    soup = BeautifulSoup(markup, "html.parser")
    name, program, batch, enrollment, photo = "", "", "", "", ""
    name_node = soup.select_one("#lblNameIDCardFront1, [id*='lblNameIDCard']")
    if name_node:
        lines = [x.strip() for x in name_node.get_text("\n").splitlines() if x.strip()]
        if lines:
            name = re.sub(r"^(Mr|Ms|Mrs|Dr|Prof)\.?\s+", "", lines[0], flags=re.I)
        if len(lines) > 1:
            program = lines[1]
        if len(lines) > 2:
            batch = lines[2]
    photo_node = soup.select_one("img#ImgPhotoIDCardFront1, img[id*='PhotoIDCard'], img[src*='ImageViewer']")
    if photo_node:
        photo = urljoin(base_url, photo_node.get("src", ""))
    back = soup.select_one("#lblInfoIDCardBack1, [id*='lblInfoIDCardBack']") or soup
    match = re.search(r"Enrollment\s*(?:No|Number)?\s*[:\s-]+\s*([A-Za-z0-9]+)", back.get_text(" ", strip=True), re.I)
    if match:
        enrollment = match.group(1)
    return {"name": name, "enrollment_number": enrollment, "profile_picture_url": photo,
            "program": program, "batch": batch}


def _parse_date(raw: str):
    cleaned = re.sub(r"[^\w\s\-/]", "", raw or "").strip()
    formats = ("%d-%m-%Y", "%d/%m/%Y", "%d-%b-%Y", "%d %b %Y",
               "%Y-%m-%d", "%Y/%m/%d", "%b %d, %Y", "%d %B %Y")
    for fmt in formats:
        try:
            return datetime.strptime(cleaned, fmt)
        except ValueError:
            pass
    try:
        return datetime.fromisoformat(cleaned)
    except ValueError:
        return None


def _exam_type(kind: str, title: str) -> str:
    combined = f"{kind} {title}".lower()
    if any(x in combined for x in ("practical", "lab", "viva")):
        return "practical"
    if any(x in combined for x in ("minor", "class test", "mid sem")):
        return "minor"
    return "theory"


def parse_exam_schedule_page(markup: str) -> list[dict]:
    if is_login_page(markup):
        return []
    soup = BeautifulSoup(markup, "html.parser")
    rows = soup.select("table tr")
    if not rows:
        return []
    indexes = {"code": -1, "title": -1, "date": -1, "time": -1, "type": -1, "room": -1, "mode": -1}
    header = next((row for row in rows if row.select("th")), rows[0])
    for i, cell in enumerate(header.select("th, td")):
        label = _clean(cell.get_text(" ", strip=True)).lower()
        if "course code" in label or "subject code" in label or label == "code":
            indexes["code"] = i
        elif "course title" in label or "subject" in label or "paper" in label:
            indexes["title"] = i
        elif "date" in label:
            indexes["date"] = i
        elif "time" in label or "slot" in label:
            indexes["time"] = i
        elif "type" in label:
            indexes["type"] = i
        elif any(x in label for x in ("room", "venue", "hall", "lab")):
            indexes["room"] = i
        elif "mode" in label:
            indexes["mode"] = i

    output = []
    for row in rows:
        cells = row.select("td")
        if not cells:
            continue
        def field(key, selector):
            node = row.select_one(selector)
            if node:
                return _clean(node.get_text(" ", strip=True))
            index = indexes[key]
            return _clean(cells[index].get_text(" ", strip=True)) if 0 <= index < len(cells) else ""
        code = field("code", "td[data-title*='Code']")
        title = field("title", "td[data-title*='Title'], td[data-title*='Subject'], td[data-title*='Paper']")
        date_text = field("date", "td[data-title*='Date']")
        time_text = field("time", "td[data-title*='Time']")
        kind = field("type", "td[data-title*='Type']")
        room = field("room", "td[data-title*='Room'], td[data-title*='Venue'], td[data-title*='Lab']")
        mode = field("mode", "td[data-title*='Mode']")
        for cell in cells:
            value = _clean(cell.get_text(" ", strip=True))
            if not code and re.fullmatch(r"[A-Z]{2,6}\d{2,4}[A-Z]?", value):
                code = value
            if not date_text and _parse_date(value):
                date_text = value
            if not time_text and re.search(r"\d{1,2}:\d{2}\s*(?:AM|PM)?", value, re.I):
                time_text = value
        parsed_date = _parse_date(date_text)
        if not parsed_date or (not code and not title):
            continue
        code = code.upper()
        stable = f"{code or title.lower()}-{parsed_date.date().isoformat()}-{time_text}"
        output.append({"id": f"amizone-{stable}", "subject_code": code,
                       "title": title or code, "date": parsed_date.date().isoformat(),
                       "time": time_text or "10:00 AM", "type": _exam_type(kind, title),
                       "room": room, "mode": mode or "Regular", "faculty": "",
                       "syllabus_summary": ""})
    return output


def parse_exam_result_page(markup: str) -> dict | None:
    if is_login_page(markup):
        return None
    soup = BeautifulSoup(markup, "html.parser")
    text = soup.get_text(" ", strip=True)
    def metric(pattern):
        match = re.search(pattern, text, re.I)
        return float(match.group(1)) if match else 0.0
    sgpa = metric(r"SGPA\s*[:=-]?\s*([\d.]+)")
    cgpa = metric(r"CGPA\s*[:=-]?\s*([\d.]+)")
    credits = metric(r"(?:Total\s*Credits?|Credits?\s*Earned)\s*[:=-]?\s*([\d.]+)")
    semester = "Current Semester"
    for heading in soup.select("h3, h4, h5, .widget-header, select option[selected]"):
        value = _clean(heading.get_text(" ", strip=True))
        if "semester" in value.lower() or re.search(r"\bsem\b", value.lower()):
            semester = value
            break

    courses = []
    for row in soup.select("tr"):
        def cell(selector):
            node = row.select_one(selector)
            return _clean(node.get_text(" ", strip=True)) if node else ""
        code = cell("td[data-title*='Code']")
        name = cell("td[data-title*='Title'], td[data-title*='Name'], td[data-title*='Subject']")
        credit_text = cell("td[data-title*='Credit']")
        grade = cell("td[data-title*='Grade']")
        point_text = cell("td[data-title*='Point']")
        status = cell("td[data-title*='Result'], td[data-title*='Status']")
        cells = row.select("td")
        if not (code or name) and len(cells) >= 4:
            possible = _clean(cells[0].get_text(" ", strip=True))
            if re.fullmatch(r"[A-Z]{2,6}\d{2,4}[A-Z]?", possible):
                code = possible
                name = _clean(cells[1].get_text(" ", strip=True))
                credit_text = _clean(cells[2].get_text(" ", strip=True))
                grade = _clean(cells[3].get_text(" ", strip=True))
                point_text = _clean(cells[4].get_text(" ", strip=True)) if len(cells) >= 5 else ""
                status = _clean(cells[5].get_text(" ", strip=True)) if len(cells) >= 6 else "Passed"
        if code or name:
            courses.append({"course_code": code, "course_name": name or code,
                            "credits": float(credit_text) if re.fullmatch(r"\d+(?:\.\d+)?", credit_text) else 0,
                            "grade": grade or "-", "grade_point": float(point_text) if re.fullmatch(r"\d+(?:\.\d+)?", point_text) else 0,
                            "result_status": status or "Passed"})
    if not courses and sgpa == 0 and cgpa == 0:
        return None
    return {"semester_name": semester, "sgpa": sgpa, "cgpa": cgpa, "total_credits": credits,
            "courses": courses, "published_date": datetime.now().date().isoformat()}
