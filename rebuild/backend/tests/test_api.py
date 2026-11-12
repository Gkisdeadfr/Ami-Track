from fastapi.testclient import TestClient
from app.main import app

def test_health():
    with TestClient(app) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["ok"] is True

def test_session_registration_rejects_empty_cookies():
    with TestClient(app) as client:
        response = client.post("/api/v1/auth/session", json={"username":"test","cookies":{}})
        assert response.status_code == 400
