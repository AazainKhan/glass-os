import json, os, subprocess, sys
import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIX = os.path.join(ROOT, 'tests', 'fixtures')
sys.path.insert(0, os.path.join(ROOT, 'tools'))
from romlib import batch_included, load_removals  # noqa: E402


def run_lint(tsv_text, tmp_path, *extra):
    tsv = tmp_path / 'r.tsv'
    tsv.write_text(tsv_text)
    return subprocess.run([sys.executable, '-I', os.path.join(ROOT, 'tools', 'lint_removals.py'),
                           os.path.join(FIX, 'manifests.json'), os.path.join(FIX, 'libs_features.txt'),
                           str(tsv), *extra], capture_output=True, text=True)


def test_required_lib_from_removed_apk_errors(tmp_path):
    r = run_lint('com.example.libowner\t1\tx\n', tmp_path)
    assert r.returncode == 1
    assert 'requires library com.example.reqlib' in r.stdout


def test_optional_lib_ok(tmp_path):
    r = run_lint('com.example.optowner\t1\tx\n', tmp_path)
    assert r.returncode == 0, r.stdout
    assert 'ERROR' not in r.stdout


def test_guarded_component_warns(tmp_path):
    # LibOwner declares the only permission guarding Core's service; Caller (kept) requests it.
    r = run_lint('com.example.libowner\t1\tx\n', tmp_path)
    assert 'WARN com.example.core/com.example.core.Svc' in r.stdout
    assert "'com.example.caller'" in r.stdout


def test_unknown_package_errors(tmp_path):
    r = run_lint('com.example.nope\t1\tx\n', tmp_path)
    assert r.returncode == 1
    assert 'not in image' in r.stdout


def test_upto_limits_batches(tmp_path):
    tsv = open(os.path.join(FIX, 'remove.tsv')).read()
    assert '4 removed' in run_lint(tsv, tmp_path).stdout
    assert '1 removed' in run_lint(tsv, tmp_path, '--upto', '1a').stdout   # batch ids may carry a letter
    assert '2 removed' in run_lint(tsv, tmp_path, '--upto', '1').stdout    # plain number covers 1a and 1b
    assert '3 removed' in run_lint(tsv, tmp_path, '--upto', '2').stdout
    assert '4 removed' in run_lint(tsv, tmp_path, '--upto', '10').stdout   # numeric, not lexical (10 > 2)


def test_batch_ordering():
    assert batch_included('1a', '1b') and not batch_included('1b', '1a')
    assert batch_included('2', '10') and not batch_included('10', '2')
    with pytest.raises(ValueError):
        batch_included('x', '1')


def test_load_removals_upto(tmp_path):
    names = [p for p, _, _ in load_removals(os.path.join(FIX, 'remove.tsv'), '1b')]
    assert names == ['com.example.tutorial', 'com.example.promo']


def test_manifest_db_reads_apk_with_aapt2(tmp_path):
    aapt2 = os.environ.get('AAPT2') or os.path.expanduser('~/Library/Android/sdk/build-tools/36.0.0/aapt2')
    sdk = os.path.expanduser('~/Library/Android/sdk/platforms')
    jars = sorted(os.path.join(sdk, d, 'android.jar') for d in os.listdir(sdk) if os.path.exists(os.path.join(sdk, d, 'android.jar'))) if os.path.isdir(sdk) else []
    if not (os.path.exists(aapt2) and jars):
        pytest.skip('aapt2 / android.jar not available')
    (tmp_path / 'root/system/system/priv-app/Fix').mkdir(parents=True)
    man = tmp_path / 'AndroidManifest.xml'
    man.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.example.fixture">
  <uses-permission android:name="android.permission.INTERNET"/>
  <permission android:name="com.example.perm.X" android:protectionLevel="signature"/>
  <application><activity android:name=".Main" android:exported="true">
    <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.HOME"/></intent-filter>
  </activity></application></manifest>''')
    apk = tmp_path / 'root/system/system/priv-app/Fix/Fix.apk'
    subprocess.run([aapt2, 'link', '-o', str(apk), '-I', jars[-1], '--manifest', str(man)], check=True)
    out = tmp_path / 'm.json'
    subprocess.run([sys.executable, '-I', os.path.join(ROOT, 'tools', 'manifest_db.py'), str(tmp_path / 'root'), str(out)], check=True)
    M = json.load(open(out))
    e = M['com.example.fixture'][0]
    assert e['file'] == 'system/system/priv-app/Fix/Fix.apk'
    assert e['uses_perm'] == ['android.permission.INTERNET']
    assert 'com.example.perm.X' in e['decl_perm']
    assert e['home'] is True


def test_graph_maps_perms_and_libs():
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import graph
    M = json.load(open(os.path.join(FIX, 'manifests.json')))
    g = graph.build(M, open(os.path.join(FIX, 'libs_features.txt')).read())
    assert 'perm:com.example.perm.GUARD' in g['deps']['com.example.caller']['com.example.libowner']
    assert 'lib-req:com.example.reqlib' in g['deps']['com.example.core']['com.example.libowner']
    assert 'com.example.optowner' not in g['deps']['com.example.core']   # optional lib
    assert 'com.example.caller' in g['rev']['com.example.libowner']
