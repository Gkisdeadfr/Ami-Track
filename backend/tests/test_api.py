from fastapi.testclient import TestClient

from app.main import app


def test_health():
    with TestClient(app) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["ok"] is True


def test_session_registration_rejects_empty_cookies():
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/auth/session",
            json={"username": "student", "cookies": {}},
        )
        assert response.status_code == 400


def test_session_registration_returns_bearer_token_without_echoing_cookies():
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/auth/session",
            json={"username": "student", "cookies": {"ASP.NET_SessionId": "not-a-real-token"}},
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["access_token"]
        assert "cookies" not in payload


def test_sync_requires_session_token():
    with TestClient(app) as client:
        response = client.post("/api/v1/sync")
        assert response.status_code == 401


def test_nexacad_route_is_publicly_fetchable_without_amizone_session(monkeypatch):
    async def fake_catalogue(codes=None):
        return [{"id": "1", "subject_code": "CSE208", "title": "PYQ"}]

    monkeypatch.setattr("app.main.fetch_catalogue", fake_catalogue)
    with TestClient(app) as client:
        response = client.get("/api/v1/nexacad/resources?subject_codes=CSE208")
        assert response.status_code == 200
        assert response.json()["resources"][0]["subject_code"] == "CSE208"
