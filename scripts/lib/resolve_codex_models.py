#!/usr/bin/env python3
"""Resolve currently available Codex models using the local app-server protocol."""

import json
import selectors
import subprocess
import sys
import time


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: resolve_codex_models.py CODEX_BIN PREFERRED_MODEL", file=sys.stderr)
        return 2

    codex_bin, preferred = sys.argv[1:]
    process = subprocess.Popen(
        [codex_bin, "app-server", "--listen", "stdio://"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        encoding="utf-8",
    )
    selector = selectors.DefaultSelector()
    assert process.stdout is not None and process.stdin is not None
    selector.register(process.stdout, selectors.EVENT_READ)

    requests = (
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "clientInfo": {
                    "name": "ai_news_model_resolver",
                    "title": "ai_news model resolver",
                    "version": "1.0.0",
                },
                "capabilities": {"experimentalApi": True},
            },
        },
        {"jsonrpc": "2.0", "method": "initialized", "params": {}},
        {"jsonrpc": "2.0", "id": 2, "method": "model/list", "params": {}},
    )

    try:
        for request in requests:
            process.stdin.write(json.dumps(request) + "\n")
            process.stdin.flush()

        deadline = time.monotonic() + 20
        models = None
        while time.monotonic() < deadline:
            if process.poll() is not None:
                break
            if not selector.select(timeout=min(0.5, deadline - time.monotonic())):
                continue
            line = process.stdout.readline()
            if not line:
                break
            try:
                response = json.loads(line)
            except json.JSONDecodeError:
                continue
            if response.get("id") != 2:
                continue
            models = response.get("result", {}).get("data")
            break

        if not isinstance(models, list):
            print("Codex app-serverからmodel/listの応答を取得できませんでした", file=sys.stderr)
            return 1

        available = [
            model
            for model in models
            if isinstance(model, dict)
            and isinstance(model.get("id"), str)
            and model["id"]
            and not model.get("hidden", False)
        ]
        if not available:
            print("Codex app-serverが利用可能モデルを返しませんでした", file=sys.stderr)
            return 1

        ordered = []
        if preferred:
            ordered.extend(model for model in available if model["id"] == preferred)
        ordered.extend(model for model in available if model.get("isDefault"))
        ordered.extend(available)

        seen = set()
        for model in ordered:
            model_id = model["id"]
            if model_id not in seen:
                print(model_id)
                seen.add(model_id)
        return 0
    finally:
        selector.close()
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


if __name__ == "__main__":
    raise SystemExit(main())
