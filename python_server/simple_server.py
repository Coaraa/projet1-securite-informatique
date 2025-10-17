#!/usr/bin/env python3
# simple_post_server.py
# Usage: python3 simple_post_server.py [PORT]
# Petit serveur de test acceptant POST et GET (sans écriture de logs).

import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs
import json
from datetime import datetime, timezone

class SimpleHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _print_event(self, body_raw: str):
        headers = {k: v for k, v in self.headers.items()}
        event = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "client_ip": self.client_address[0],
            "method": self.command,
            "path": self.path,
            "headers": headers,
            "body_raw": body_raw
        }
        print(json.dumps(event, ensure_ascii=False, indent=2))

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body_bytes = self.rfile.read(length) if length > 0 else b""
        body_raw = body_bytes.decode("utf-8", errors="replace")

        self._print_event(body_raw)

        resp = {"status": "received", "marker": "SIEM_TEST", "length": len(body_raw)}
        resp_bytes = json.dumps(resp).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(resp_bytes)))
        self.end_headers()
        self.wfile.write(resp_bytes)

    def do_GET(self):
        html = (
            "<html><body>"
            "<h3>SIEM Test Server</h3>"
            "<p>Use POST requests to test payloads.</p>"
            "</body></html>"
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(html)))
        self.end_headers()
        self.wfile.write(html)

    def log_message(self, format, *args):
        # désactive les logs HTTP par défaut
        return

def run(port=8000):
    httpd = HTTPServer(("", port), SimpleHandler)
    print(f"Server running on port {port} (Ctrl+C to stop)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    run(port)
