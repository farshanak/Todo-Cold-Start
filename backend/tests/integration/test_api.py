"""
Integration tests for the Todo HTTP API.

Uses FastAPI's TestClient (ASGI in-process) to validate routing, request
parsing, CORS-middleware wiring and the 404 branches end-to-end.
"""
import pytest
from fastapi.testclient import TestClient

pytestmark = pytest.mark.integration


def test_health_endpoint(client: TestClient) -> None:
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_list_is_empty_initially(client: TestClient) -> None:
    r = client.get("/todos")
    assert r.status_code == 200
    assert r.json() == []


def test_create_returns_todo_with_id(client: TestClient) -> None:
    r = client.post("/todos", json={"title": "buy milk"})
    assert r.status_code == 200
    todo = r.json()
    assert todo["title"] == "buy milk"
    assert todo["done"] is False
    assert isinstance(todo["id"], int)


def test_list_includes_created_todo(client: TestClient) -> None:
    created = client.post("/todos", json={"title": "walk dog"}).json()
    body = client.get("/todos").json()
    assert len(body) == 1
    assert body[0]["id"] == created["id"]
    assert body[0]["title"] == "walk dog"


def test_patch_toggles_done(client: TestClient) -> None:
    created = client.post("/todos", json={"title": "toggle me"}).json()

    r = client.patch(f"/todos/{created['id']}")
    assert r.status_code == 200
    assert r.json()["done"] is True

    r = client.patch(f"/todos/{created['id']}")
    assert r.json()["done"] is False


def test_delete_removes_todo(client: TestClient) -> None:
    created = client.post("/todos", json={"title": "delete me"}).json()
    r = client.delete(f"/todos/{created['id']}")
    assert r.status_code == 200
    assert r.json() == {"ok": True}
    assert client.get("/todos").json() == []


def test_patch_missing_returns_404(client: TestClient) -> None:
    r = client.patch("/todos/99999")
    assert r.status_code == 404


def test_delete_missing_returns_404(client: TestClient) -> None:
    r = client.delete("/todos/99999")
    assert r.status_code == 404
