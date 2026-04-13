"""
Shared test fixtures (Gold Standard).

Rules:
1. All mocks should use `unittest.mock.create_autospec` — never bare `Mock()`.
2. Fixtures are the single source of truth for test dependencies.
3. Add new fixtures here, not in individual test files.
"""
import pytest
from fastapi.testclient import TestClient
from main import _todos, app


@pytest.fixture
def client() -> TestClient:
    """FastAPI TestClient with a clean in-memory todo store per test."""
    _todos.clear()
    return TestClient(app)
