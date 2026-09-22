#!/usr/bin/env python3
import socket
import sys
import threading
import time

HOST = "0.0.0.0"
PORT = 6667

def main():
    ready = threading.Event()
    deadline = time.time() + 40
    connection_no = 0

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((HOST, PORT))
        srv.listen(1)
        srv.settimeout(1.0)
        ready.set()
        while time.time() < deadline:
            try:
                conn, addr = srv.accept()
            except socket.timeout:
                continue
            connection_no += 1
            with conn:
                print(f"IRC_TEST_ACCEPT {connection_no} {addr[0]}:{addr[1]}", flush=True)
                conn.settimeout(12)
                conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                # Legacy Dancer waits for initial server traffic before sending
                # its IRC registration. Real IRC daemons commonly emit an
                # AUTH/ident notice immediately after accept.
                conn.sendall(b":irc-test NOTICE AUTH :*** Looking up your hostname...\r\n")
                buf = b""
                nick = None
                user = None
                pong_ok = False
                join_ok = False
                while time.time() < deadline:
                    try:
                        chunk = conn.recv(4096)
                    except socket.timeout:
                        print("IRC_TEST_READ_TIMEOUT", file=sys.stderr, flush=True)
                        break
                    if not chunk:
                        print("IRC_TEST_EOF", file=sys.stderr, flush=True)
                        break
                    buf += chunk
                    while b"\r\n" in buf:
                        raw, buf = buf.split(b"\r\n", 1)
                        line = raw.decode("latin1", "replace")
                        print(line, flush=True)
                        parts = line.split()
                        if parts and parts[0].upper() == "NICK" and len(parts) >= 2:
                            nick = parts[1]
                        if parts and parts[0].upper() == "USER" and len(parts) >= 2:
                            user = parts[1]
                        if line.upper().startswith("PING "):
                            token = line.split(" ", 1)[1]
                            conn.sendall(f"PONG {token}\r\n".encode())
                        if nick and user:
                            conn.sendall(f":irc-test 001 {nick} :Dancer integration test\r\n".encode())
                            ping_token = f"dancer-ci-ping-{connection_no}"
                            conn.sendall(f"PING :{ping_token}\r\n".encode())
                            print("DANCER_IRC_HANDSHAKE_OK", flush=True)
                            nick = None
                            user = None
                        if line.upper() in (f"PONG :DANCER-CI-PING-{connection_no}", f"PONG DANCER-CI-PING-{connection_no}"):
                            pong_ok = True
                            print("DANCER_IRC_PING_PONG_OK", flush=True)
                        if parts and parts[0].upper() == "JOIN" and len(parts) >= 2 and parts[1].rstrip().lower() == "#dancer-ci":
                            join_ok = True
                            print("DANCER_IRC_JOIN_OK", flush=True)
                        if pong_ok and join_ok:
                            if connection_no == 1:
                                print("DANCER_IRC_CHANNEL_OK", flush=True)
                                print("DANCER_IRC_FORCE_RECONNECT", flush=True)
                                conn.shutdown(socket.SHUT_RDWR)
                                break
                            print("DANCER_IRC_RECONNECT_OK", flush=True)
                            return 0
                    if pong_ok and join_ok and connection_no == 1:
                        break
        print("DANCER_IRC_RECONNECT_TIMEOUT", file=sys.stderr, flush=True)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
