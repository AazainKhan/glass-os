import json, os, subprocess, sys
import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIX = os.path.join(ROOT, 'tests', 'fixtures')
TOOL = os.path.join(ROOT, 'tools', 'replace_list.py')


def run(tsv, *args):
    return subprocess.run([sys.executable, '-I', TOOL, os.path.join(FIX, 'manifests.json'), tsv, *args],
                          capture_output=True, text=True)


@pytest.fixture
def tsv(tmp_path):
    p = tmp_path / 'r.tsv'
    p.write_text(open(os.path.join(FIX, 'remove.tsv')).read() +
                 'com.example.libowner\t3\tsystem_ext package\n')
    return str(p)


def test_system_ext_maps_to_system_prefix(tsv):
    r = run(tsv, '--upto', '3')
    assert 'system/system_ext/priv-app/LibOwner' in r.stdout.splitlines()


def test_product_maps_under_system(tsv):
    r = run(tsv, '--upto', '10')
    lines = r.stdout.splitlines()
    assert 'system/product/app/ProductApp' in lines
    assert 'system/vendor/app/VendorApp' in lines
    assert 'system/app/Tutorial' in lines


def test_upto_filters(tsv):
    assert run(tsv, '--upto', '1a').stdout.splitlines() == ['system/app/Tutorial']
    assert len(run(tsv, '--upto', '1').stdout.splitlines()) == 2
    assert 'system/product/app/ProductApp' not in run(tsv, '--upto', '3').stdout


def test_same_set_both_formats(tsv):
    m = run(tsv, '--upto', '10', '--format', 'magisk').stdout.splitlines()
    p = run(tsv, '--upto', '10', '--format', 'paths').stdout.splitlines()
    assert len(m) == len(p) == 5
    # same directories: the last path component matches pairwise after sorting by leaf
    assert sorted(x.rsplit('/', 1)[1] for x in m) == sorted(x.rsplit('/', 1)[1] for x in p)
    assert 'system\t/system/system_ext/priv-app/LibOwner' in p
    assert 'product\t/app/ProductApp' in p
    assert 'vendor\t/app/VendorApp' in p


def test_unknown_pkg_errors(tmp_path):
    t = tmp_path / 'r.tsv'
    t.write_text('com.example.nope\t1\tx\n')
    r = run(str(t), '--upto', '1')
    assert r.returncode == 1 and 'not in image' in r.stderr


def test_deterministic(tsv):
    assert run(tsv, '--upto', '10').stdout == run(tsv, '--upto', '10').stdout


REAL = os.path.join(ROOT, 'work', 'manifests.json')


@pytest.mark.skipif(not os.path.exists(REAL), reason='needs work/manifests.json (local OTA extraction)')
def test_real_removals_keep_profile_packages():
    r = subprocess.run([sys.executable, '-I', TOOL, REAL, os.path.join(ROOT, 'config', 'remove-candidates.tsv'),
                        '--upto', '8'], capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    out = r.stdout
    assert 'com.amazon.tahoe' in out and 'com.amazon.cloud9' in out and 'com.amazon.tmm.tutorial' in out
    for keep in ('profilepicker', 'parentalcontrols', 'tv.settings.v2', 'priv-app/com.amazon.venezia', 'com.amazon.aria'):
        assert keep not in out
    assert len(out.splitlines()) >= 36
