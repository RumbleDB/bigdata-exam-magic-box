"""Talk LSP to the JSONiq language server through the JupyterLab extension's
WebSocket, exactly the way JupyterLab does, and check it reports a syntax
error in a broken query."""

import asyncio
import json
import sys

from tornado.websocket import websocket_connect

URL = "ws://localhost:8888/jsoniq/language-server"


async def main():
    ws = await websocket_connect(URL)

    async def send(message):
        await ws.write_message(json.dumps(message))

    await send({"jsonrpc": "2.0", "id": 1, "method": "initialize",
                "params": {"processId": None, "rootUri": "file:///home", "capabilities": {}}})
    await send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
    await send({"jsonrpc": "2.0", "method": "textDocument/didOpen",
                "params": {"textDocument": {"uri": "file:///home/broken.jq", "languageId": "jsoniq",
                                            "version": 1, "text": "for $x in (1, 2, 3) retur $x"}}})

    initialized, diagnostics = False, []

    async def read():
        nonlocal initialized
        while (raw := await ws.read_message()) is not None:
            message = json.loads(raw)
            if message.get("id") == 1 and "result" in message:
                initialized = True
            if message.get("method") == "textDocument/publishDiagnostics":
                diagnostics.extend(message["params"]["diagnostics"])
                if diagnostics:
                    return

    try:
        await asyncio.wait_for(read(), timeout=120)
    except TimeoutError:
        pass
    ws.close()

    print("initialize:", "ok" if initialized else "FAILED")
    print("diagnostics:", [d["message"][:80] for d in diagnostics][:2] or "NONE")
    return 0 if initialized and diagnostics else 1


sys.exit(asyncio.run(main()))
