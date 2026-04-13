"""
Pure unit tests for backend/config.py.

No I/O, no HTTP — just verify Settings loads and the CORS origin validator
handles both the string-from-env and explicit-list branches.
"""
import pytest
from config import Settings

pytestmark = pytest.mark.unit


def test_cors_origins_split_from_env_string(monkeypatch: pytest.MonkeyPatch) -> None:
    """String env value is split on commas and stripped."""
    monkeypatch.setenv("CORS_ORIGINS", "http://a.test, http://b.test ,http://c.test")
    s = Settings(_env_file=None)
    assert s.cors_origins == ["http://a.test", "http://b.test", "http://c.test"]


def test_cors_origins_empty_parts_dropped(monkeypatch: pytest.MonkeyPatch) -> None:
    """Empty segments (trailing comma, double comma) are dropped."""
    monkeypatch.setenv("CORS_ORIGINS", "http://a.test,,")
    s = Settings(_env_file=None)
    assert s.cors_origins == ["http://a.test"]


def test_cors_origins_explicit_list_passthrough(monkeypatch: pytest.MonkeyPatch) -> None:
    """When cors_origins is passed as a Python list, the validator returns it unchanged."""
    monkeypatch.delenv("CORS_ORIGINS", raising=False)
    s = Settings(
        _env_file=None,
        cors_origins=["http://d.test", "http://e.test"],
    )
    assert s.cors_origins == ["http://d.test", "http://e.test"]


def test_cors_origins_default_when_unset(monkeypatch: pytest.MonkeyPatch) -> None:
    """With no env and no file, the default factory supplies dev origins."""
    monkeypatch.delenv("CORS_ORIGINS", raising=False)
    s = Settings(_env_file=None)
    assert "http://127.0.0.1:5500" in s.cors_origins
    assert "http://localhost:5500" in s.cors_origins


def test_host_port_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("HOST", raising=False)
    monkeypatch.delenv("PORT", raising=False)
    s = Settings(_env_file=None)
    assert s.host == "127.0.0.1"
    assert s.port == 8000
    assert s.log_level == "info"


def test_port_coerces_from_string(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("PORT", "9090")
    s = Settings(_env_file=None)
    assert s.port == 9090
