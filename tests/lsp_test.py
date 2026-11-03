"""Talk LSP to the JSONiq language server exactly the way jupyter-lsp launches it,
and check it reports a syntax error in a broken query."""

import json
import os
import subprocess
import sys
import threading
import time

from jupyter_lsp import LanguageServerManager

manager = LanguageServerManager()
manager.initialize()
spec = manager.language_servers.get("jsoniq-language-server")
if not spec:
    sys.exit("FAIL: jupyter-lsp does not find jsoniq-language-server")

proc = subprocess.Popen(
    spec["argv"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    env={**os.environ, **spec.get("env", {})},
)
messages = []


def send(message):
    body = json.dumps(message).encode()
    proc.stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
    proc.stdin.flush()


def read_messages():
    while True:
        headers = {}
        while (line := proc.stdout.readline().decode()) not in ("\r\n", ""):
            key, value = line.split(":", 1)
            headers[key.lower()] = value.strip()
        if not headers:
            return
        messages.append(json.loads(proc.stdout.read(int(headers["content-length"]))))


def diagnostics():
    return [
        d
        for m in messages
        if m.get("method") == "textDocument/publishDiagnostics"
        for d in m["params"]["diagnostics"]
    ]


threading.Thread(target=read_messages, daemon=True).start()
send({"jsonrpc": "2.0", "id": 1, "method": "initialize",
      "params": {"processId": None, "rootUri": "file:///home", "capabilities": {}}})
send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
send({"jsonrpc": "2.0", "method": "textDocument/didOpen",
      "params": {"textDocument": {"uri": "file:///home/broken.jq", "languageId": "jsoniq",
                                  "version": 1, "text": "for $x in (1, 2, 3) retur $x"}}})

deadline = time.time() + 120
while time.time() < deadline and not diagnostics():
    time.sleep(1)
proc.kill()

initialized = any(m.get("id") == 1 and "result" in m for m in messages)
print("initialize:", "ok" if initialized else "FAILED")
print("diagnostics:", [d["message"][:80] for d in diagnostics()][:2] or "NONE")
sys.exit(0 if initialized and diagnostics() else 1)
