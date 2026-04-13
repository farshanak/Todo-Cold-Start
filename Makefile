.PHONY: test test-unit test-integration test-cov test-tia lint

PYTEST := backend/.venv/bin/pytest
PYTHON := backend/.venv/bin/python

test:
	$(PYTEST)

test-unit:
	$(PYTEST) -m unit

test-integration:
	$(PYTEST) -m integration

test-cov:
	$(PYTEST) --cov=backend --cov-report=term-missing --cov-fail-under=80

# Test Impact Analysis: run only tests related to changed files locally.
# CI always runs the full suite (Safety Latch) regardless of CI=true.
test-tia:
	@if [ "$$CI" = "true" ]; then \
		echo "🔒 CI Safety Latch: running FULL suite with coverage"; \
		$(PYTEST) --cov=backend --cov-fail-under=80; \
	else \
		echo "🎯 TIA: running tests for changed backend files"; \
		CHANGED=$$(git diff --name-only origin/main...HEAD -- 'backend/**/*.py' 2>/dev/null || true); \
		if [ -z "$$CHANGED" ]; then \
			CHANGED=$$(git diff --name-only HEAD -- 'backend/**/*.py' 2>/dev/null || true); \
		fi; \
		if [ -z "$$CHANGED" ]; then \
			echo "✅ No backend changes — nothing to run"; exit 0; \
		fi; \
		echo "Changed files:"; echo "$$CHANGED" | sed 's/^/  /'; \
		$(PYTEST) $$CHANGED || $(PYTEST); \
	fi

lint:
	backend/.venv/bin/ruff check backend
