from datetime import datetime, timezone
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .schemas import SessionRegistration, SessionResponse, SessionStatus, SyncResponse, StudentProfile
from .security import issue_token
from .session_store import PortalSession, sessions
from .amizone_client import AmizoneClient
from .amizone_parser import is_login_page, parse_attendance_page, parse_course_list_page, parse_profile
from .nexacad import fetch_catalogue

app = FastAPI(title="Ami-Track API", version="2.0.0", description="Amizone + NexAcad student companion API")
origins = [x.strip() for x in settings.allowed_origins.split(",") if x.strip()]
app.add_middleware(CORSMiddleware, allow_origins=origins, allow_credentials=False,
                   allow_methods=["GET", "POST", "DELETE"], allow_headers=["Authorization", "Content-Type"])

def current_session(authorization: str | None = Header(default=None)) -> PortalSession:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Missing Ami-Track access token")
    session = sessions.get(authorization.split(" ", 1)[1].strip())
    if not session:
        raise HTTPException(401, "Session expired. Sign in with Amizone again.")
    return session

@app.get("/health")
async def health():
    return {"ok": True, "service": "ami-track-api", "version": "2.0.0"}

@app.post("/api/v1/auth/session", response_model=SessionResponse)
async def register_session(payload: SessionRegistration):
    if not payload.cookies:
        raise HTTPException(400, "No Amizone cookies were provided")
    # Never log cookies or include them in any response.
    token, expires = issue_token()
    sessions.put(token, PortalSession(payload.username, payload.cookies, payload.user_agent, expires))
    return SessionResponse(access_token=token, expires_at=expires)

@app.get("/api/v1/auth/validate", response_model=SessionStatus)
async def validate(session: PortalSession = Depends(current_session)):
    checked = datetime.now(timezone.utc)
    client = AmizoneClient(session)
    try:
        html = await client.get_html("/Home")
        valid = not is_login_page(html) and "Please check your credential" not in html
        return SessionStatus(valid=valid, username=session.username, checked_at=checked,
                             message="Authenticated" if valid else "Amizone session expired")
    except Exception:
        return SessionStatus(valid=False, username=session.username, checked_at=checked,
                             message="Could not validate the Amizone session")
    finally:
        await client.close()

@app.post("/api/v1/sync", response_model=SyncResponse)
async def sync(session: PortalSession = Depends(current_session)):
    client = AmizoneClient(session)
    warnings: list[str] = []
    try:
        home = await client.get_html("/Home")
        if is_login_page(home):
            raise HTTPException(401, "Amizone session expired. Sign in again.")
        profile = parse_profile(home, settings.portal_base)
        attendance = parse_attendance_page(home)
        course_html = await client.get_html("/Academics/MyCourses")
        courses = parse_course_list_page(course_html)
        if not attendance:
            warnings.append("Amizone returned no attendance rows. The My Attendance widget markup may have changed.")
        # Merge attendance counts into the course/internal-mark records.
        attendance_by_code = {x["subject_code"]: x for x in attendance}
        merged = []
        for course in courses:
            att = attendance_by_code.get(course["subject_code"])
            if att:
                course.update({k: att[k] for k in ("attended", "held", "percentage")})
            merged.append(course)
        if not merged:
            merged = attendance
        return SyncResponse(synced_at=datetime.now(timezone.utc), profile=StudentProfile(**profile),
                            attendance=attendance, courses=merged, warnings=warnings)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(502, f"Amizone sync failed: {type(exc).__name__}") from exc
    finally:
        await client.close()

@app.delete("/api/v1/auth/session")
async def clear_session(session: PortalSession = Depends(current_session),
                        authorization: str = Header()):
    sessions.delete(authorization.split(" ", 1)[1].strip())
    return {"ok": True}

@app.get("/api/v1/nexacad/resources")
async def nexacad_resources(subject_codes: str = ""):
    codes = [x.strip().upper() for x in subject_codes.split(",") if x.strip()]
    try:
        return {"resources": await fetch_catalogue(codes or None)}
    except Exception as exc:
        raise HTTPException(502, f"NexAcad catalogue unavailable: {type(exc).__name__}") from exc
