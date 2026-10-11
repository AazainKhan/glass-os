import json, os, re, subprocess, sys
import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, 'tools', 'privapp_xml.py')
AAPT2 = os.environ.get('AAPT2') or os.path.expanduser('~/Library/Android/sdk/build-tools/36.0.0/aapt2')
SDK = os.path.expanduser('~/Library/Android/sdk/platforms')
JARS = sorted(os.path.join(SDK, d, 'android.jar') for d in os.listdir(SDK)
              if os.path.exists(os.path.join(SDK, d, 'android.jar'))) if os.path.isdir(SDK) else []
pytestmark = pytest.mark.skipif(not (os.path.exists(AAPT2) and JARS), reason='aapt2 / android.jar missing')


def make_apk(tmp_path, perms, pkg='com.example.priv', name='app.apk'):
    man = tmp_path / (name + '.xml')
    uses = ''.join(f'<uses-permission android:name="{p}"/>' for p in perms)
    man.write_text(f'<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="{pkg}">{uses}<application/></manifest>')
    apk = tmp_path / name
    subprocess.run([AAPT2, 'link', '-o', str(apk), '-I', JARS[-1], '--manifest', str(man)], check=True)
    return str(apk)


def run(*args):
    return subprocess.run([sys.executable, '-I', TOOL, *args], capture_output=True, text=True)


def write_kt(tmp_path, body='"com.android.providers.tv.permission.ACCESS_ALL_EPG_DATA",\n        "com.android.providers.tv.permission.ACCESS_WATCHED_PROGRAMS",'):
    kt = tmp_path / 'RootFeatures.kt'
    kt.write_text(f'object X {{\n    private val EXTRA_PRIVILEGED = listOf(\n        {body}\n    )\n}}\n')
    return str(kt)


def names(xml):
    return re.findall(r'<permission name="([^"]+)"/>', xml)


def test_allowlist_covers_requested(tmp_path):
    want = ['android.permission.WRITE_SECURE_SETTINGS', 'android.permission.INTERNET', 'android.permission.PACKAGE_USAGE_STATS']
    apk = make_apk(tmp_path, want)
    r = run(apk, '--extra-from', write_kt(tmp_path))
    assert r.returncode == 0, r.stderr
    assert set(want) <= set(names(r.stdout))
    assert 'com.android.providers.tv.permission.ACCESS_ALL_EPG_DATA' in r.stdout
    assert '<privapp-permissions package="com.example.priv">' in r.stdout


def test_sorted_and_stable(tmp_path):
    apk = make_apk(tmp_path, ['b.PERM', 'a.PERM', 'c.PERM'])
    a = run(apk).stdout
    assert a == run(apk).stdout
    assert names(a) == sorted(names(a))


def test_missing_extra_list_fails(tmp_path):
    apk = make_apk(tmp_path, ['a.PERM'])
    kt = tmp_path / 'Empty.kt'
    kt.write_text('object X { val NOTHING = 1 }\n')
    r = run(apk, '--extra-from', str(kt))
    assert r.returncode == 1 and 'EXTRA_PRIVILEGED not found' in r.stderr
    assert r.stdout == ''
    assert run(apk, '--extra-from', str(tmp_path / 'nope.kt')).returncode == 1


def test_declared_filter_drops_api31_names_but_keeps_requested_declared(tmp_path):
    apk = make_apk(tmp_path, ['android.permission.INSTALL_PACKAGES', 'android.permission.UPDATE_PACKAGES_WITHOUT_USER_ACTION'])
    mj = tmp_path / 'm.json'
    mj.write_text(json.dumps({'android': [{'decl_perm': {'android.permission.INSTALL_PACKAGES': 'signature'}}]}))
    r = run(apk, '--declared-from', str(mj))
    assert names(r.stdout) == ['android.permission.INSTALL_PACKAGES']
    r = run(apk, '--declared-from', str(mj), '--keep', 'android.permission.DELETE_PACKAGES')
    assert 'android.permission.DELETE_PACKAGES' in names(r.stdout)


GLASS = os.path.expanduser('~/Documents/glass-launcher/app/build/outputs/apk/release/app-release.apk')
KT = os.path.expanduser('~/Documents/glass-launcher/app/src/main/java/dev/glasslauncher/system/RootFeatures.kt')


@pytest.mark.skipif(not (os.path.exists(GLASS) and os.path.exists(KT)), reason='needs a local Glass release build')
def test_real_glass_apk_covers_every_permission():
    r = run(GLASS, '--extra-from', KT)
    assert r.returncode == 0, r.stderr
    dump = subprocess.run([AAPT2, 'dump', 'permissions', GLASS], capture_output=True, text=True).stdout
    for p in re.findall(r"^uses-permission: name='([^']+)'", dump, re.M):
        assert p in names(r.stdout)
    assert 'com.android.providers.tv.permission.ACCESS_ALL_EPG_DATA' in names(r.stdout)
