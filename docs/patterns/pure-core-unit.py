"""
PATTERN: Pure Core Unit Test

Location: backend/tests/unit/test_*.py
When: Code has NO I/O, NO framework imports, NO side effects.
Rule: If it imports fastapi/requests/boto3/etc., it's NOT a unit test — move to integration.
Rule: If Mock Tax > 2.0x (test LOC > 2x source LOC), delete and write an integration test.

Example (lives at backend/tests/unit/test_config.py for real):
"""
import pytest

from config import Settings

pytestmark = pytest.mark.unit


def test_pure_function_returns_expected_value() -> None:
    # ARRANGE: plain data, no mocks
    s = Settings(_env_file=None, cors_origins=["http://x.test"])

    # ACT
    result = s.cors_origins

    # ASSERT
    assert result == ["http://x.test"]


def test_edge_case_empty_input(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CORS_ORIGINS", ",,")
    s = Settings(_env_file=None)
    assert s.cors_origins == []
