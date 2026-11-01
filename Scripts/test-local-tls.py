#!/usr/bin/env python3
"""Run the app's negative TLS test against a disposable, untrusted HTTPS server."""
import http.server
import os
from pathlib import Path
import ssl
import subprocess
import sys
import tempfile
import threading

class Fixture(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"untrusted content")

with tempfile.TemporaryDirectory() as tmp, http.server.HTTPServer(("127.0.0.1", 0), Fixture) as server:
    cert, key = (str(Path(tmp) / name) for name in ("cert.pem", "key.pem"))
    config = Path(tmp) / "openssl.cnf"
    config.write_text("[req]\ndistinguished_name=dn\nx509_extensions=extensions\n"
                      "[dn]\n[extensions]\nsubjectAltName=IP:127.0.0.1\n")
    subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
                    "-keyout", key, "-out", cert, "-days", "1", "-subj", "/CN=localhost",
                    "-config", str(config)], check=True)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"https://127.0.0.1:{server.server_port}/quote"
    if sys.argv[1:] == ["--integration"]:
        command = ["bash", "Scripts/test-integration.sh"]
    else:
        command = ["xcodebuild", "-project", "MotivationDaily.xcodeproj", "-scheme", "MotivationDaily",
                    "-destination", os.getenv("TEST_DESTINATION", "platform=iOS Simulator,name=iPhone 11,OS=27.0"),
                    "-parallel-testing-enabled", "NO", "-onlyUsePackageVersionsFromResolvedFile",
                    "-only-testing:MotivationDailyTests/FailurePathTests", *sys.argv[1:], "test"]
    subprocess.run(command,
                   cwd=Path(__file__).resolve().parents[1],
                   env={**os.environ, "TEST_RUNNER_MOTIVATION_TLS_FIXTURE": url}, check=True)
