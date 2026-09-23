#!/usr/bin/env python3
import os, socket, sys, time

host=sys.argv[1]
port=int(sys.argv[2]) if len(sys.argv)>2 else 6667
nick=os.environ.get("IRCD_PROBE_NICK","dancer-probe")
channel=os.environ.get("IRCD_PROBE_CHANNEL","#dancer-ci")
deadline=time.time()+15
s=socket.create_connection((host,port),timeout=5)
s.settimeout(1)
s.sendall(f"NICK {nick}\r\nUSER {nick} 0 * :Dancer CI probe\r\n".encode())
registered=False
joined=False
buf=b""
while time.time()<deadline:
    try: data=s.recv(4096)
    except socket.timeout: continue
    if not data: break
    buf+=data
    while b"\n" in buf:
        raw,buf=buf.split(b"\n",1)
        line=raw.rstrip(b"\r").decode("utf-8","replace")
        print(line,flush=True)
        if line.startswith("PING "):
            s.sendall(("PONG "+line[5:]+"\r\n").encode())
        parts=line.split()
        if len(parts)>=2 and parts[1]=="001":
            registered=True
            s.sendall(f"JOIN {channel}\r\n".encode())
        if registered and ((len(parts)>=2 and parts[1] in ("353","366") and channel in parts) or (" JOIN " in line and channel in line)):
            joined=True
            break
    if joined: break
s.close()
if not registered:
    print("IRCD_PROBE_REGISTRATION_FAILED",file=sys.stderr); sys.exit(1)
if not joined:
    print("IRCD_PROBE_JOIN_FAILED",file=sys.stderr); sys.exit(1)
print("IRCD_PROBE_OK")
