from datetime import datetime

from pydantic import BaseModel, Field


class SessionRegistration(BaseModel):
    username: str = Field(min_length=1, max_length=100)
    cookies: dict[str, str]
    user_agent: str | None = None


class SessionResponse(BaseModel):
    access_token: str
    expires_at: datetime


class SessionStatus(BaseModel):
    valid: bool
    username: str
    checked_at: datetime
    message: str


class CourseAttendance(BaseModel):
    id: str
    subject_code: str
    subject_name: str
    attended: int
    held: int
    percentage: float
    internal_marks: float = 0
    max_internal: float = 40
    course_type: str = "Compulsory"
    credits: int = 4


class StudentProfile(BaseModel):
    name: str = ""
    enrollment_number: str = ""
    profile_picture_url: str = ""
    program: str = ""
    batch: str = ""


class ExamItem(BaseModel):
    id: str
    subject_code: str = ""
    title: str
    date: str
    time: str = ""
    type: str = "theory"
    room: str = ""
    faculty: str = ""
    mode: str = "Regular"
    syllabus_summary: str = ""


class GradeItem(BaseModel):
    course_code: str
    course_name: str
    credits: float = 0
    grade: str = "-"
    grade_point: float = 0
    result_status: str = "Passed"


class SemesterResult(BaseModel):
    semester_name: str
    sgpa: float = 0
    cgpa: float = 0
    total_credits: float = 0
    courses: list[GradeItem] = Field(default_factory=list)
    published_date: datetime | None = None


class ResourceItem(BaseModel):
    id: str
    subject_code: str
    subject_name: str = ""
    title: str
    file_type: str = "Notes"
    size: str = ""
    preview_url: str
    download_url: str


class SyncResponse(BaseModel):
    synced_at: datetime
    profile: StudentProfile
    attendance: list[CourseAttendance] = Field(default_factory=list)
    courses: list[CourseAttendance] = Field(default_factory=list)
    exams: list[ExamItem] = Field(default_factory=list)
    results: list[SemesterResult] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
