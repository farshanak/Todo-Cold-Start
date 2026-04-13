"""
PATTERN: Adapter Verification Test

Location: backend/tests/integration/test_*_adapter.py
When: Testing thin I/O wrappers (filesystem, git, external HTTP, database drivers).
Key: Use REAL I/O against temporary directories / local fixtures — never mock the boundary
     you're trying to verify.

Example — filesystem adapter against a real temp dir:
"""
from pathlib import Path

import pytest

pytestmark = pytest.mark.integration


def test_read_file_from_real_disk(tmp_path: Path) -> None:
    # ARRANGE: real file on disk
    file_path = tmp_path / "note.txt"
    file_path.write_text("hello")

    # ACT: adapter boundary — real read
    content = file_path.read_text()

    # ASSERT
    assert content == "hello"


def test_missing_file_raises(tmp_path: Path) -> None:
    missing = tmp_path / "does-not-exist.txt"
    with pytest.raises(FileNotFoundError):
        missing.read_text()
