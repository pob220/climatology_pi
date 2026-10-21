"""Import through the real stock Plugin Manager and verify visible Windows versions."""
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import urllib.request

root = Path(__file__).resolve().parents[2]
archive = Path(sys.argv[1]).resolve()
host = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else root / '.windows86-host/host'
output = root / 'artifacts/windows-version'
output.mkdir(parents=True, exist_ok=True)
if len(sys.argv) == 2:
    installer = host.parent / 'opencpn-5.14.2-x86.exe'
    url = 'https://github.com/OpenCPN/OpenCPN/releases/download/Release_5.14.2/opencpn_5.14.2-0%2B4828.37fcbab_setup.exe'
    expected = 'ef43f23018c1577b05b6e7333bcf89becc8f3cdad2051c958a5fc778ca9de25d'
    installer.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(url, installer)
    assert hashlib.sha256(installer.read_bytes()).hexdigest() == expected
    subprocess.run(['7z','x','-y','-o'+str(host),str(installer)],check=True)
assert os.environ.get('GITHUB_ACTIONS') == 'true', 'This test requires a disposable Windows CI VM'
environment = dict(os.environ, LOCALAPPDATA=str(output/'local-appdata'), APPDATA=str(output/'roaming-appdata'))
environment['PATH'] = str(host) + os.pathsep + environment['PATH']
buffer = ctypes.create_unicode_buffer(32768)
assert ctypes.windll.shell32.SHGetFolderPathW(None,35,None,0,buffer) == 0
config = Path(buffer.value) / 'opencpn/opencpn.ini'
assert not config.exists(), 'Refusing to replace an existing OpenCPN profile'
binary = (host/'opencpn.exe').read_bytes()
versions = re.findall(rb'5\.14\.2(?:-[A-Za-z0-9._]+)?(?:\+[A-Za-z0-9._]+)?\x00',binary)
dates = re.findall(rb'20\d{2}-\d{2}-\d{2}\x00',binary)
assert versions and dates
version = max(versions,key=len)[:-1].decode()
date = max(dates)[:-1].decode()
config.parent.mkdir(parents=True,exist_ok=True)
config.write_text(f'[Settings]\nConfigVersionString=Version {version} Build {date}\nNavMessageShown=1\nOpenGL=0\nDisableOpenGL=1\nShowMenuBar=1\n[PlugIns/climatology_pi.dll]\nbEnabled=1\n',encoding='utf-8')
for name,args in [('abi',['print-abi']),('import',['import-plugin',str(archive)])]:
    command = subprocess.run([str(host/'opencpn-cmd.exe'),*args],cwd=host,env=environment,capture_output=True,text=True,timeout=90)
    (output/f'{name}.log').write_text(command.stdout+command.stderr,encoding='utf-8')
    assert command.returncode == 0, (name,command.returncode,command.stdout,command.stderr)
library = Path(environment['LOCALAPPDATA']) / 'opencpn/plugins/climatology_pi.dll'
assert library.is_file(), 'Plugin Manager did not install the DLL'
with tarfile.open(archive) as tar:
    for item in tar:
        if item.isfile() and '/plugins/' in item.name:
            suffix = item.name.split('/plugins/',1)[1]
            installed = library.parent / suffix
            assert installed.is_file() and installed.read_bytes() == tar.extractfile(item).read(), suffix
subprocess.run(['pwsh','-File',str(root/'ci/public-packages/windows-version.ps1'),'-HostRoot',str(host),'-Output',str(output)],env=environment,check=True,timeout=120)
print('Stock OpenCPN imported the exact package bytes and displayed Climatology 2.0.0')
