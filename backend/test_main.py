from fastapi.testclient import TestClient

from main import _todos, app

client = TestClient(app)


def setup_function(_):
    _todos.clear()


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_list_empty():
    r = client.get("/todos")
    assert r.status_code == 200
    assert r.json() == []


def test_create_and_list():
    r = client.post("/todos", json={"title": "buy milk"})
    assert r.status_code == 200
    todo = r.json()
    assert todo["title"] == "buy milk"
    assert todo["done"] is False
    assert isinstance(todo["id"], int)

    r = client.get("/todos")
    assert r.status_code == 200
    body = r.json()
    assert len(body) == 1
    assert body[0]["id"] == todo["id"]


def test_toggle_done():
    created = client.post("/todos", json={"title": "toggle me"}).json()
    r = client.patch(f"/todos/{created['id']}")
    assert r.status_code == 200
    assert r.json()["done"] is True

    r = client.patch(f"/todos/{created['id']}")
    assert r.json()["done"] is False


def test_delete():
    created = client.post("/todos", json={"title": "delete me"}).json()
    r = client.delete(f"/todos/{created['id']}")
    assert r.status_code == 200
    assert r.json() == {"ok": True}
    assert client.get("/todos").json() == []


def test_toggle_missing_404():
    r = client.patch("/todos/99999")
    assert r.status_code == 404


def test_delete_missing_404():
    r = client.delete("/todos/99999")
    assert r.status_code == 404


def test_settings_cors_parse_from_env(monkeypatch):
    monkeypatch.setenv("CORS_ORIGINS", "http://a.test, http://b.test")
    from config import Settings
    s = Settings()
    assert s.cors_origins == ["http://a.test", "http://b.test"]
