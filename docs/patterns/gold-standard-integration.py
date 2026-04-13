"""
PATTERN: Gold Standard Integration Test

Location: backend/tests/integration/test_*.py
When: Code uses HTTP handlers, database, framework middleware, or external I/O.
Rules:
  1. Uses shared fixtures from backend/tests/conftest.py (NEVER inline `Mock()` in test bodies).
  2. Add new capabilities to conftest.py, not to individual test files.
  3. For mocks, always `unittest.mock.create_autospec(Interface, instance=True)` — never bare `Mock()`.

Example (lives at backend/tests/integration/test_api.py for real):
"""
import pytest
from fastapi.testclient import TestClient

pytestmark = pytest.mark.integration


def test_endpoint_happy_path(client: TestClient) -> None:
    # ARRANGE: shared `client` fixture resets state per test
    payload = {"title": "buy milk"}

    # ACT
    r = client.post("/todos", json=payload)

    # ASSERT
    assert r.status_code == 200
    assert r.json()["title"] == "buy milk"


def test_endpoint_returns_404_on_missing_resource(client: TestClient) -> None:
    r = client.patch("/todos/99999")
    assert r.status_code == 404
