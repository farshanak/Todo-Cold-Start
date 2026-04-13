# Test Pattern Templates

These are the north-star templates referenced by Mault's TDD enforcement system.
Adapt them to your project's actual services and interfaces — the structure and
principles are what matter, not the specific class names.

## Test layer routing

| Source file pattern        | Required test layer   | Test location                         |
|---------------------------|-----------------------|----------------------------------------|
| `backend/*.py`            | Pure Core Unit        | `backend/tests/unit/test_*.py`         |
| `backend/main.py` (HTTP)  | Gold Standard         | `backend/tests/integration/test_*.py`  |
| `backend/adapters/*.py`   | Adapter Verification  | `backend/tests/integration/test_*_adapter.py` |

## Rules

1. **Pure Core Unit** — no framework imports, no I/O. If you need `fastapi` or `boto3`,
   it's an integration test.
2. **Gold Standard Integration** — use shared fixtures from `backend/tests/conftest.py`.
   Never inline `Mock()`; always `create_autospec(Interface, instance=True)`.
3. **Adapter Verification** — use real I/O (`tmp_path`, real sockets on high ports, etc.)
   against controlled fixtures. The whole point is to validate the boundary.

## Mock Tax rule

If your test LOC exceeds **2× source LOC** because of mocks, delete the unit test
and write an integration test instead. Heavy mocks indicate the wrong layer.
