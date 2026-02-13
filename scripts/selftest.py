#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path


def _run(args: list[str], env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
    )


def _assert(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    script = root / "scripts" / "grok_search.py"

    env = os.environ.copy()
    # Keep selftest deterministic: depth path should not be shadowed by model env vars.
    env.pop("GROK_MODEL", None)
    env.pop("GROK2API_MODEL", None)

    # 1) Depth mapping should be applied.
    ok_run = _run(
        [
            sys.executable,
            str(script),
            "--depth",
            "fast",
            "--query",
            "返回ok",
            "--timeout-seconds",
            "45",
        ],
        env=env,
    )
    _assert(ok_run.returncode == 0, f"depth-fast failed: rc={ok_run.returncode} stderr={ok_run.stderr.strip()}")

    try:
        payload = json.loads(ok_run.stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"depth-fast output is not valid JSON: {e}") from e

    _assert(payload.get("ok") is True, "depth-fast did not return ok=true")
    _assert(payload.get("depth") == "fast", f"depth-fast mismatch: {payload.get('depth')}")
    _assert(str(payload.get("model_source") or "").startswith("depth:"), "depth-fast did not use depth model mapping")
    _assert(isinstance(payload.get("sources"), list), "sources is not a list")
    print("OK: depth-fast request")

    # 2) Invalid depth should fail fast with exit code 2.
    bad_run = _run(
        [
            sys.executable,
            str(script),
            "--depth",
            "invalid-depth",
            "--query",
            "test",
            "--timeout-seconds",
            "10",
        ],
        env=env,
    )
    _assert(bad_run.returncode == 2, f"invalid depth should return rc=2, got {bad_run.returncode}")
    _assert("Unknown depth" in bad_run.stderr, "invalid depth error message missing")
    print("OK: invalid-depth validation")

    print("OK: selftest passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
