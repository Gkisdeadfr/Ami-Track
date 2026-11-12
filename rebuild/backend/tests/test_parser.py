from pathlib import Path

from app.amizone_parser import (
    is_login_page,
    parse_attendance_page,
    parse_course_list_page,
    parse_exam_result_page,
    parse_exam_schedule_page,
    parse_profile_id_card,
)
from app.nexacad import parse_catalogue_bundle

FIXTURES = Path(__file__).parent / "fixtures"


def test_attendance_parser_uses_only_my_attendance_widget():
    html = (FIXTURES / "amizone_home.html").read_text()
    result = parse_attendance_page(html)
    assert [row["subject_code"] for row in result] == ["MATH242", "CSE208", "FREN144"]
    assert result[0]["attended"] == 46
    assert result[0]["held"] == 48
    assert result[2]["percentage"] == 66.67


def test_login_page_is_not_parsed_as_empty_success():
    markup = '<form id="loginform"><input name="_Password"></form>'
    assert is_login_page(markup)
    assert parse_attendance_page(markup) == []


def test_course_parser_handles_amizone_internal_mark_format():
    html = (FIXTURES / "amizone_courses.html").read_text()
    result = parse_course_list_page(html)
    assert len(result) == 2
    assert result[0]["subject_code"] == "MATH242"
    assert result[0]["attended"] == 46
    assert result[0]["held"] == 48
    assert result[0]["internal_marks"] == 35.0
    assert result[0]["max_internal"] == 40.0
    assert result[1]["internal_marks"] == 28.5


def test_exam_schedule_parser_reads_dates_and_venues():
    html = """
    <table>
      <tr><th>Course Code</th><th>Course Title</th><th>Date</th><th>Time</th><th>Type</th><th>Venue</th></tr>
      <tr><td>CSE208</td><td>Discrete Mathematics</td><td>12-Nov-2026</td>
      <td>10:00 AM</td><td>Theory</td><td>A-Block 204</td></tr>
    </table>
    """
    result = parse_exam_schedule_page(html)
    assert len(result) == 1
    assert result[0]["subject_code"] == "CSE208"
    assert result[0]["date"] == "2026-11-12"
    assert result[0]["room"] == "A-Block 204"


def test_exam_result_parser_reads_sgpa_and_grades():
    html = """
    <h3>Semester 3</h3><div>SGPA: 8.75 CGPA: 8.42 Total Credits: 22</div>
    <table><tr><th>Code</th><th>Name</th><th>Credits</th><th>Grade</th><th>Point</th><th>Status</th></tr>
      <tr><td data-title="Code">CSE208</td><td data-title="Name">Discrete Mathematics</td>
      <td data-title="Credit">4</td><td data-title="Grade">A</td><td data-title="Point">9</td>
      <td data-title="Status">Passed</td></tr>
    </table>
    """
    result = parse_exam_result_page(html)
    assert result is not None
    assert result["sgpa"] == 8.75
    assert result["cgpa"] == 8.42
    assert result["courses"][0]["grade"] == "A"


def test_id_card_parser_extracts_program_batch_and_enrollment():
    html = """
    <div id="lblNameIDCardFront1">Mr Example Student<br>B.Tech CSE<br>2025-2029</div>
    <img id="ImgPhotoIDCardFront1" src="/ImageViewer/Index?id=123">
    <div id="lblInfoIDCardBack1">Enrollment No: A1234567890</div>
    """
    result = parse_profile_id_card(html, "https://s.amizone.net")
    assert result["name"] == "Example Student"
    assert result["program"] == "B.Tech CSE"
    assert result["batch"] == "2025-2029"
    assert result["enrollment_number"] == "A1234567890"


def test_nexacad_catalogue_bundle_is_decoded_and_classified():
    script = '''
    window.EMBEDDED_COURSE_CATALOG = {
      CSE208: {name: "Discrete Mathematics", children: [
        {type: "folder", name: "Module 1", children: [
          {type: "file", name: "Previous Year Question Paper.pdf",
           fileId: "1AbCdEfGhIjKlMnOpQrSt", size: "1048576"}
        ]}
      ]}
    };
    '''
    resources = parse_catalogue_bundle(script)
    assert len(resources) == 1
    assert resources[0]["subject_code"] == "CSE208"
    assert resources[0]["file_type"] == "PYQ"
    assert resources[0]["size"] == "1.0 MB"
