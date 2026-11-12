from app.amizone_parser import parse_attendance_page, parse_course_list_page, is_login_page

def test_attendance_scoped_to_widget():
    html = """
    <div class='panel'><h4 class='panel-title'>My Attendance</h4>
      <ul id='tasks'><li><span class='sub-code'>CSE101</span><span class='lbl'>Programming</span><span class='class-count'>18/20</span></li></ul>
    </div>
    <ul><li><span class='sub-code'>FAKE101</span><span class='class-count'>9/10</span></li></ul>
    """
    result = parse_attendance_page(html)
    assert len(result) == 1
    assert result[0]["subject_code"] == "CSE101"
    assert result[0]["attended"] == 18
    assert result[0]["held"] == 20

def test_login_page_is_not_parsed_as_empty_success():
    assert is_login_page("<form id='loginform'></form>")
    assert parse_attendance_page("<form id='loginform'></form>") == []

def test_course_internal_marks():
    html = """
    <table><tr><th>Code</th><th>Name</th><th>Internal Marks</th></tr>
    <tr><td data-title='Code'>CSE101</td><td data-title='Name'>Programming</td>
    <td data-title='Internal Marks'>32/40</td></tr></table>
    """
    result = parse_course_list_page(html)
    assert result[0]["internal_marks"] == 32
    assert result[0]["max_internal"] == 40
