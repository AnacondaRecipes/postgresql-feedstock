import subprocess
import sys
from pathlib import Path

patches = [
    'patches/fix_gssapi_setenv_win.patch',
    'patches/fix_x509_name_win.patch',
    'patches/fix_auth_setenv_win.patch',
]

files = [
    'src/backend/libpq/be-secure-gssapi.c',
    'src/backend/libpq/auth.c',
    'src/include/common/openssl.h',
]

for f in files:
    p = Path(f)
    if p.exists():
        content = p.read_bytes().replace(b'\r\n', b'\n')
        p.write_bytes(content)

for patch in patches:
    cmd = ['patch', '-p1', '-i', patch]
    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit(1)