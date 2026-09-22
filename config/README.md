# Dancer configuration

Operator configuration belongs here and is mounted read-only at `/config`.

M0 deliberately does not invent Dancer configuration filenames or command-line
arguments. Those are added after the exact upstream 4.16 source archive has
been inspected and successfully qualified on Alpine/musl.

Do not commit passwords, IRC service credentials, or other secrets.
