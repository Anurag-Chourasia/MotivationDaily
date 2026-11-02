#!/usr/bin/env python3
"""Run the app's negative TLS tests against disposable, isolated HTTPS servers."""
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
        self.wfile.write(b"untrusted fixture content")

    def log_message(self, *args):
        pass  # Quiet test server logs


def generate_self_signed_cert(directory: Path) -> tuple[str, str]:
    """Generate a self-signed certificate for 127.0.0.1 valid today."""
    key = str(directory / "self_signed_key.pem")
    cert = str(directory / "self_signed_cert.pem")
    cfg = directory / "self_signed.cnf"
    cfg.write_text(
        "[req]\ndistinguished_name=dn\nx509_extensions=ext\n"
        "[dn]\n[ext]\nsubjectAltName=IP:127.0.0.1\n"
    )
    subprocess.run(
        [
            "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
            "-keyout", key, "-out", cert, "-days", "1",
            "-subj", "/CN=localhost", "-config", str(cfg)
        ],
        check=True,
        capture_output=True
    )
    return key, cert


def generate_expired_cert(directory: Path) -> tuple[str, str]:
    """Generate a certificate with start/end dates in the past."""
    ca_key = str(directory / "ca_key.pem")
    ca_cert = str(directory / "ca_cert.pem")
    ca_cfg = directory / "ca.cnf"
    ca_cfg.write_text(
        f"[ ca ]\ndefault_ca = CA_default\n"
        f"[ CA_default ]\ndir = {directory}\n"
        f"database = {directory / 'index.txt'}\n"
        f"new_certs_dir = {directory / 'newcerts'}\n"
        f"certificate = {ca_cert}\n"
        f"serial = {directory / 'serial'}\n"
        f"private_key = {ca_key}\n"
        f"default_days = 365\ndefault_md = sha256\npolicy = policy_any\n"
        f"[ policy_any ]\ncommonName = supplied\n"
        f"[ req ]\ndistinguished_name = dn\nx509_extensions = ext\n"
        f"[ dn ]\n[ ext ]\nsubjectAltName = IP:127.0.0.1\n"
    )
    (directory / "index.txt").touch()
    (directory / "serial").write_text("01\n")
    (directory / "newcerts").mkdir(exist_ok=True)

    subprocess.run(
        [
            "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
            "-keyout", ca_key, "-out", ca_cert, "-days", "365",
            "-subj", "/CN=TestCA", "-config", str(ca_cfg)
        ],
        check=True,
        capture_output=True
    )

    exp_key = str(directory / "expired_key.pem")
    exp_csr = str(directory / "expired.csr")
    exp_cert = str(directory / "expired_cert.pem")

    subprocess.run(
        [
            "openssl", "req", "-newkey", "rsa:2048", "-nodes",
            "-keyout", exp_key, "-out", exp_csr,
            "-subj", "/CN=127.0.0.1", "-config", str(ca_cfg)
        ],
        check=True,
        capture_output=True
    )

    subprocess.run(
        [
            "openssl", "ca", "-batch", "-config", str(ca_cfg),
            "-in", exp_csr, "-out", exp_cert,
            "-extensions", "ext",
            "-startdate", "20200101000000Z", "-enddate", "20200102000000Z"
        ],
        check=True,
        capture_output=True
    )
    return exp_key, exp_cert


def generate_wrong_host_cert(directory: Path) -> tuple[str, str]:
    """Generate a certificate whose Subject Alternative Name does not match 127.0.0.1."""
    wh_key = str(directory / "wrong_host_key.pem")
    wh_cert = str(directory / "wrong_host_cert.pem")
    wh_cfg = directory / "wrong_host.cnf"
    wh_cfg.write_text(
        "[req]\ndistinguished_name=dn\nx509_extensions=ext\n"
        "[dn]\n[ext]\nsubjectAltName=DNS:wrong.domain.internal\n"
    )
    subprocess.run(
        [
            "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
            "-keyout", wh_key, "-out", wh_cert, "-days", "1",
            "-subj", "/CN=wrong.domain.internal", "-config", str(wh_cfg)
        ],
        check=True,
        capture_output=True
    )
    return wh_key, wh_cert


def start_tls_server(key_path: str, cert_path: str) -> http.server.HTTPServer:
    server = http.server.HTTPServer(("127.0.0.1", 0), Fixture)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert_path, key_path)
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)

        ss_key, ss_cert = generate_self_signed_cert(tmp_dir)
        exp_key, exp_cert = generate_expired_cert(tmp_dir)
        wh_key, wh_cert = generate_wrong_host_cert(tmp_dir)

        s_self_signed = start_tls_server(ss_key, ss_cert)
        s_expired = start_tls_server(exp_key, exp_cert)
        s_wrong_host = start_tls_server(wh_key, wh_cert)

        url_self_signed = f"https://127.0.0.1:{s_self_signed.server_port}/quote"
        url_expired = f"https://127.0.0.1:{s_expired.server_port}/quote"
        url_wrong_host = f"https://127.0.0.1:{s_wrong_host.server_port}/quote"

        print(f"Started self-signed server on {url_self_signed}")
        print(f"Started expired cert server on {url_expired}")
        print(f"Started wrong-host server on {url_wrong_host}")

        if sys.argv[1:] == ["--integration"]:
            command = ["bash", "Scripts/test-integration.sh"]
        else:
            destination = os.getenv(
                "TEST_DESTINATION",
                "platform=iOS Simulator,name=iPhone 11,OS=27.0"
            )
            command = [
                "xcodebuild", "-project", "MotivationDaily.xcodeproj",
                "-scheme", "MotivationDaily",
                "-destination", destination,
                "-parallel-testing-enabled", "NO",
                "-onlyUsePackageVersionsFromResolvedFile",
                "-only-testing:MotivationDailyTests/FailurePathTests",
                *sys.argv[1:], "test"
            ]

        env = {
            **os.environ,
            "TEST_RUNNER_MOTIVATION_TLS_FIXTURE": url_self_signed,
            "TEST_RUNNER_MOTIVATION_TLS_EXPIRED_FIXTURE": url_expired,
            "TEST_RUNNER_MOTIVATION_TLS_WRONG_HOST_FIXTURE": url_wrong_host,
        }

        try:
            subprocess.run(
                command,
                cwd=Path(__file__).resolve().parents[1],
                env=env,
                check=True
            )
        finally:
            s_self_signed.shutdown()
            s_expired.shutdown()
            s_wrong_host.shutdown()


if __name__ == "__main__":
    main()
