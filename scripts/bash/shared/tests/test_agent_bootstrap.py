import hashlib
import io
import itertools
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tarfile
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'agent-bootstrap.sh'
REPOSITORY = SCRIPT.parents[3]
POLICY = (REPOSITORY / 'dotfiles/agents/AGENTS.md').read_bytes()
ROLES = [
    'feature, refactoring', 'bug-fix', 'perf-issue', 'hillclimb', 'judgment and prose',
    'strongest judgment', 'how explorer', 'how explainer', 'why investigators',
    'why synthesizer', 'reflect tooling', 'reflect judgment, divergent, synthesizer',
    'arena runners', 'arena cross-judge pool', 'swarm workers', 'architect runners',
    'interrogate reviewers',
]
PANELS = {'arena runners', 'arena cross-judge pool', 'architect runners', 'interrogate reviewers'}
TRANSPORT = '''import os
from pathlib import Path
import shutil
import sys
import time

fixtures = Path(os.environ['AGENT_BOOTSTRAP_FIXTURES'])
args = sys.argv[1:]
url = next(arg for arg in args if arg.startswith('https://'))
name = 'dotfiles' if '/m1yon/dotfiles/' in url else 'pstack'
with (fixtures / 'requests').open('a') as output:
    output.write(name + ' ' + str(time.monotonic()) + '\\n')
if (fixtures / 'delay').exists():
    time.sleep(float((fixtures / 'delay').read_text()))
if (fixtures / 'fail').exists() and (fixtures / 'fail').read_text() in ('all', name):
    sys.exit(22)
shutil.copyfile(fixtures / (name + '.tgz'), args[args.index('-o') + 1])
'''


def archive(path, root, files, commit, malicious=None):
    with tarfile.open(path, 'w:gz', format=tarfile.PAX_FORMAT, pax_headers={'comment': commit}) as output:
        root_member = tarfile.TarInfo(root + '/')
        root_member.type = tarfile.DIRTYPE
        output.addfile(root_member)
        for name, data in files.items():
            entry = tarfile.TarInfo(root + '/' + name)
            entry.mode = 0o755 if name.endswith('.sh') else 0o644
            entry.size = len(data)
            output.addfile(entry, io.BytesIO(data))
        if malicious:
            output.addfile(*malicious)


def package(extra='retired', version='1.0.0'):
    files = {
        '.codex-plugin/plugin.json': json.dumps({'name': 'pstack', 'version': version, 'skills': './skills/'}).encode(),
        '.claude-plugin/plugin.json': json.dumps({'name': 'pstack', 'version': version}).encode(),
        'models.json': json.dumps({
            'roles': [{'role': role, 'models': 'panel' if role in PANELS else 'default'} for role in ROLES],
            'efforts': ['low', 'medium', 'high', 'xhigh', 'max'],
        }).encode(),
        'hooks/session-start-context.md': b'User instructions take precedence. Invoke `pstack:poteto-mode`.\n'
            b'Use `pstack:architect` and `pstack:reflect` when requested.\n',
        'hooks/session-start.sh': b'#!/bin/sh\ntouch SHOULD_NEVER_RUN\n',
        'skills/poteto-mode/references/codex-tools.md': b'Codex tool mapping\n',
        'skills/poteto-mode/playbooks/feature.md': b'Feature playbook\n',
        'skills/poteto-mode/scripts/check-playbooks.mjs': b'console.log("fixture")\n',
        'skills/poteto-mode/references/licenses/LICENSE': b'License dependency\n',
        'agents/poteto-agent.md': b'Agent reference\n',
        'scripts/helper.sh': b'#!/bin/sh\necho helper\n',
    }
    for name in ('poteto-mode', 'architect', 'reflect', extra):
        files['skills/' + name + '/SKILL.md'] = ('---\nname: ' + name
            + '\ndescription: Fixture skill\n---\nRead sibling references.\n').encode()
    return {'plugins/pstack/' + name: data for name, data in files.items()} | {'LICENSE': b'Upstream license\n'}


class BootstrapTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='agent-bootstrap-test-')
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / 'target'
        self.home.mkdir()
        self.fixtures = self.root / 'fixtures'
        self.fixtures.mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        transport = self.root / 'transport.py'
        transport.write_text(TRANSPORT)
        wrapper = self.bin / 'curl'
        wrapper.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' '
                           + shlex.quote(str(transport)) + ' "$@"\n')
        wrapper.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        AGENT_BOOTSTRAP_TARGET_HOME=str(self.home),
                        AGENT_BOOTSTRAP_FIXTURES=str(self.fixtures))
        self.write_fixtures()

    def tearDown(self):
        self.temporary.cleanup()

    def write_fixtures(self, extra='retired', version='1.0.0', policy=POLICY, files=None, malicious=None, commit=None):
        archive(self.fixtures / 'dotfiles.tgz', 'dotfiles-master',
                {'dotfiles/agents/AGENTS.md': policy}, 'a' * 40)
        archive(self.fixtures / 'pstack.tgz', 'pstack-claude-main', files or package(extra, version),
                commit or ('b' if version == '1.0.0' else 'c') * 40, malicious)

    def run_bootstrap(self, success=True, script=SCRIPT):
        result = subprocess.run(['sh', str(script)], env=self.env, cwd=self.home,
                                capture_output=True, text=True, timeout=20)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def state(self):
        return self.home / '.local/share/agent-bootstrap'

    def snapshot(self):
        result = {}
        for relative in ('.codex/AGENTS.md', '.codex/pstack-models.md', '.agents/skills/pstack',
                         '.local/share/agent-bootstrap/current'):
            path = self.home / relative
            result[relative] = os.readlink(path) if path.is_symlink() else path.read_bytes()
        current = self.state() / 'current'
        result['release'] = {str(path.relative_to(current)): hashlib.sha256(path.read_bytes()).hexdigest()
                             for path in current.rglob('*') if path.is_file()}
        return result

    def test_install_repeat_upgrade_and_preservation(self):
        codex = self.home / '.codex'
        codex.mkdir()
        prefix = b'User bytes\r\nwith no final newline'
        (codex / 'AGENTS.md').write_bytes(prefix)
        personal = self.home / '.agents/skills/personal/SKILL.md'
        personal.parent.mkdir(parents=True)
        personal.write_bytes(b'---\nname: personal\ndescription: Mine\n---\nPersonal content\n')
        result = self.run_bootstrap()
        self.assertIn('4 skills', result.stdout)
        first = self.snapshot()
        self.run_bootstrap()
        self.assertEqual(first, self.snapshot())
        agents = codex / 'AGENTS.md'
        suffix = b'\nUser suffix\xff\n'
        agents.write_bytes(agents.read_bytes() + suffix)
        self.write_fixtures(extra='replacement', version='1.1.0',
                            policy=POLICY.replace(b'feature, refactoring: gpt-6.1-sol @high',
                                                  b'feature, refactoring: gpt-6.1-sol @medium'))
        self.run_bootstrap()
        current = self.state() / 'current'
        self.assertFalse((current / 'pstack/skills/retired').exists())
        self.assertTrue((current / 'pstack/skills/replacement/SKILL.md').is_file())
        self.assertEqual((current / 'pstack/scripts/helper.sh').stat().st_mode & 0o777, 0o755)
        self.assertEqual((current / 'pstack/skills/poteto-mode/references/licenses/LICENSE').read_bytes(), b'License dependency\n')
        self.assertEqual((current / 'LICENSE').read_bytes(), b'Upstream license\n')
        self.assertTrue(agents.read_bytes().startswith(prefix + b'\n'))
        self.assertTrue(agents.read_bytes().endswith(suffix))
        self.assertEqual(agents.read_bytes().count(b'<!-- agent-bootstrap:start -->'), 1)
        routing = package()['plugins/pstack/hooks/session-start-context.md']
        self.assertEqual((current / 'routing.md').read_bytes(), routing)
        self.assertIn(routing, agents.read_bytes())
        self.assertEqual((current / 'pstack/.codex-plugin/plugin.json').read_bytes(),
                         package(version='1.1.0')['plugins/pstack/.codex-plugin/plugin.json'])
        self.assertIn(b'User instructions take precedence.', agents.read_bytes())
        sheet = (codex / 'pstack-models.md').read_text()
        self.assertIn('feature, refactoring: gpt-6.1-sol @medium', sheet)
        self.assertIn('panel vendors: any', sheet)
        self.assertTrue(all(role + ': ' in sheet for role in ROLES))
        self.assertEqual(len(list((self.state() / 'releases').iterdir())), 2)
        self.assertFalse((self.home / 'SHOULD_NEVER_RUN').exists())
        self.assertEqual(personal.read_bytes(), b'---\nname: personal\ndescription: Mine\n---\nPersonal content\n')
        receipt = json.loads((current / 'receipt.json').read_text())
        self.assertEqual(receipt['pstack_commit'], 'c' * 40)
        self.assertEqual(receipt['skills'], ['architect', 'poteto-mode', 'reflect', 'replacement'])
        self.assertEqual(receipt['script_sha256'], hashlib.sha256(SCRIPT.read_bytes()).hexdigest())
        self.assertFalse(list(self.state().glob('.prepare-*')))

    def test_network_and_invalid_archive_leave_active_state_unchanged(self):
        self.run_bootstrap()
        before = self.snapshot()
        for failure in ('dotfiles', 'pstack'):
            with self.subTest(failure=failure):
                (self.fixtures / 'fail').write_text(failure)
                self.run_bootstrap(success=False)
                self.assertEqual(before, self.snapshot())
        (self.fixtures / 'fail').unlink()
        for attack in ('truncated', 'traversal', 'absolute', 'symlink', 'hardlink', 'duplicate', 'commit'):
            with self.subTest(attack=attack):
                self.write_fixtures()
                if attack == 'truncated':
                    (self.fixtures / 'pstack.tgz').write_bytes(b'\x1f\x8btruncated')
                elif attack == 'commit':
                    self.write_fixtures(commit='main')
                else:
                    name = {'traversal': 'pstack-claude-main/../escape', 'absolute': '/escape',
                            'duplicate': 'pstack-claude-main/LICENSE'}.get(attack, 'pstack-claude-main/plugins/pstack/link')
                    member = tarfile.TarInfo(name)
                    if attack in ('symlink', 'hardlink'):
                        member.type = tarfile.SYMTYPE if attack == 'symlink' else tarfile.LNKTYPE
                        member.linkname = '/outside'
                    self.write_fixtures(malicious=(member, None))
                self.run_bootstrap(success=False)
                self.assertEqual(before, self.snapshot())
                self.assertFalse((self.home / 'escape').exists())

    def test_unselected_archive_symlink_is_not_extracted(self):
        member = tarfile.TarInfo('dotfiles-master/dotfiles/opencode/AGENTS.md')
        member.type = tarfile.SYMTYPE
        member.linkname = '../agents/AGENTS.md'
        archive(self.fixtures / 'dotfiles.tgz', 'dotfiles-master',
                {'dotfiles/agents/AGENTS.md': POLICY}, 'a' * 40, (member, None))
        self.run_bootstrap()
        self.assertFalse((self.state() / 'current/dotfiles/opencode/AGENTS.md').exists())

    def test_ownership_conflicts_preserve_sources(self):
        cases = ('agents-parent', 'skills-parent', 'codex-parent', 'state-parent', 'agents-file',
                 'sheet-file', 'pstack-directory', 'pstack-link', 'sheet-unowned',
                 'ambiguous-skill', 'markers')
        for case in cases:
            with self.subTest(case=case):
                case_home = self.root / case
                case_home.mkdir()
                self.env['AGENT_BOOTSTRAP_TARGET_HOME'] = str(case_home)
                source = self.root / (case + '-source')
                source.mkdir()
                sentinel = source / 'sentinel'
                sentinel.write_bytes(b'preserve source')
                if case.endswith('parent'):
                    target = {'agents-parent': '.agents', 'skills-parent': '.agents/skills',
                              'codex-parent': '.codex', 'state-parent': '.local'}[case]
                    path = case_home / target
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.symlink_to(source, target_is_directory=True)
                elif case in ('agents-file', 'sheet-file'):
                    codex = case_home / '.codex'
                    codex.mkdir()
                    (codex / ('AGENTS.md' if case == 'agents-file' else 'pstack-models.md')).symlink_to(sentinel)
                elif case.startswith('pstack-'):
                    path = case_home / '.agents/skills/pstack'
                    path.parent.mkdir(parents=True)
                    path.mkdir() if case == 'pstack-directory' else path.symlink_to(source)
                elif case == 'sheet-unowned':
                    path = case_home / '.codex/pstack-models.md'
                    path.parent.mkdir()
                    path.write_bytes(b'feature, refactoring: mine\n')
                elif case == 'ambiguous-skill':
                    path = case_home / '.agents/skills/mine'
                    path.mkdir(parents=True)
                    (path / 'SKILL.md').write_bytes(b'---\nname: [mine]\ndescription: Mine\n---\n')
                else:
                    path = case_home / '.codex/AGENTS.md'
                    path.parent.mkdir()
                    path.write_bytes(b'User\n<!-- agent-bootstrap:start -->\nbroken\n')
                before = {str(path.relative_to(source)): path.read_bytes() for path in source.rglob('*') if path.is_file()}
                self.run_bootstrap(success=False)
                self.assertEqual(before, {str(path.relative_to(source)): path.read_bytes() for path in source.rglob('*') if path.is_file()})
                self.assertFalse((case_home / '.local/share/agent-bootstrap/current').exists())

    def test_namespace_conflicts_in_both_user_roots(self):
        cases = itertools.product(('.agents/skills', '.codex/skills'),
                                  ('root', 'nested', 'linked'),
                                  ('.codex-plugin', '.claude-plugin'))
        for index, (relative, location, manifest_directory) in enumerate(cases):
            with self.subTest(root=relative, location=location, manifest=manifest_directory):
                self.home = self.root / ('conflict-' + str(index))
                self.home.mkdir()
                self.env['AGENT_BOOTSTRAP_TARGET_HOME'] = str(self.home)
                root = self.home / relative
                root.mkdir(parents=True)
                package_root = root if location == 'root' else root / 'mine'
                if location == 'linked':
                    source = self.root / ('linked-package-' + str(index))
                    source.mkdir()
                    package_root.symlink_to(source, target_is_directory=True)
                manifest = package_root / manifest_directory / 'plugin.json'
                manifest.parent.mkdir(parents=True)
                manifest.write_text(json.dumps({'name': 'pstack', 'skills': './'}))
                skill = package_root / 'SKILL.md'
                skill.write_bytes(b'---\nname: "architect"\ndescription: Mine\n---\n')
                before = skill.read_bytes()
                result = self.run_bootstrap(success=False)
                self.assertIn('overlapping skill name', result.stderr)
                self.assertEqual(skill.read_bytes(), before)
                self.assertFalse((self.state() / 'current').exists())

    def test_unrelated_bare_and_nearest_namespaced_skills_are_preserved(self):
        for relative in ('.agents/skills', '.codex/skills'):
            root = self.home / relative
            root.mkdir(parents=True)
            (root / 'SKILL.md').write_bytes(b'---\nname: architect\ndescription: Mine\n---\n')
            (root / 'loop').symlink_to(root, target_is_directory=True)
            outer_manifest = root / 'outer/.claude-plugin/plugin.json'
            outer_manifest.parent.mkdir(parents=True)
            outer_manifest.write_text(json.dumps({'name': 'pstack'}))
            inner = root / 'outer/inner'
            manifest = inner / '.codex-plugin/plugin.json'
            manifest.parent.mkdir(parents=True)
            manifest.write_text(json.dumps({'name': 'personal', 'skills': './'}))
            claude_manifest = inner / '.claude-plugin/plugin.json'
            claude_manifest.parent.mkdir()
            claude_manifest.write_text(json.dumps({'name': 'pstack'}))
            (inner / 'SKILL.md').write_bytes(b"---\nname: 'architect'\ndescription: Mine\n---\n")
        self.run_bootstrap()
        self.run_bootstrap()
        for relative in ('.agents/skills', '.codex/skills'):
            root = self.home / relative
            self.assertIn(b'name: architect', (root / 'SKILL.md').read_bytes())
            self.assertIn(b"name: 'architect'", (root / 'outer/inner/SKILL.md').read_bytes())

    def test_edited_generated_outputs_and_retained_release_refused(self):
        self.run_bootstrap()
        for relative in ('.codex/AGENTS.md', '.codex/pstack-models.md',
                         '.local/share/agent-bootstrap/current/pstack/models.json'):
            with self.subTest(relative=relative):
                path = self.home / relative
                original = path.read_bytes()
                if relative.endswith('AGENTS.md'):
                    path.write_bytes(original.replace(b'NEVER commit', b'NEVER publish'))
                else:
                    path.write_bytes(original + b'edited\n')
                before = self.snapshot()
                self.run_bootstrap(success=False)
                self.assertEqual(before, self.snapshot())
                path.write_bytes(original)
        self.run_bootstrap()

    def test_malformed_and_unowned_policy_blocks_refused(self):
        marker = b'<!-- agent-bootstrap:start -->\n'
        end = b'<!-- agent-bootstrap:end -->\n'
        for content in (end + marker, marker + b'x\n', marker + marker + end + end,
                        marker + end + marker + end, marker + b'forged\n' + end,
                        b'user' + marker + end, b'<!-- agent-bootstrap:unknown -->\n'):
            with self.subTest(content=content):
                path = self.home / '.codex/AGENTS.md'
                path.parent.mkdir(exist_ok=True)
                path.write_bytes(content)
                self.run_bootstrap(success=False)
                self.assertEqual(path.read_bytes(), content)
                self.assertFalse((self.state() / 'current').exists())

    def test_invalid_policy_and_upstream_contract_refused(self):
        self.run_bootstrap()
        before = self.snapshot()
        for change in ('missing-role', 'unknown-role', 'bad-effort', 'duplicate-role',
                       'new-upstream-role', 'routing', 'missing-dependency',
                       'missing-codex-manifest', 'wrong-namespace', 'wrong-skills-root'):
            with self.subTest(change=change):
                policy = POLICY
                files = package()
                if change == 'missing-role':
                    policy = re.sub(rb'^bug-fix:.*\n', b'', policy, flags=re.M)
                elif change == 'unknown-role':
                    policy += b'extra-role: gpt-6-sol\n'
                elif change == 'bad-effort':
                    policy = policy.replace(b'@high', b'@wrong')
                elif change == 'duplicate-role':
                    policy += b'bug-fix: gpt-6-astra @xhigh\n'
                elif change == 'new-upstream-role':
                    models = json.loads(files['plugins/pstack/models.json'])
                    models['roles'].append({'role': 'new role', 'models': 'default'})
                    files['plugins/pstack/models.json'] = json.dumps(models).encode()
                elif change == 'routing':
                    files['plugins/pstack/hooks/session-start-context.md'] += b'pstack:missing\n'
                elif change == 'missing-codex-manifest':
                    del files['plugins/pstack/.codex-plugin/plugin.json']
                elif change in ('wrong-namespace', 'wrong-skills-root'):
                    manifest = json.loads(files['plugins/pstack/.codex-plugin/plugin.json'])
                    manifest['name' if change == 'wrong-namespace' else 'skills'] = 'other'
                    files['plugins/pstack/.codex-plugin/plugin.json'] = json.dumps(manifest).encode()
                else:
                    del files['plugins/pstack/skills/poteto-mode/references/codex-tools.md']
                self.write_fixtures(policy=policy, files=files)
                self.run_bootstrap(success=False)
                self.assertEqual(before, self.snapshot())

    def test_interrupted_publication_recovers_from_adjacent_releases(self):
        for first_install, stop_after in itertools.product((False, True), range(1, 5)):
            with self.subTest(first_install=first_install, stop_after=stop_after):
                case_home = self.root / ('interrupted-' + str(first_install) + '-' + str(stop_after))
                case_home.mkdir()
                self.home = case_home
                self.env['AGENT_BOOTSTRAP_TARGET_HOME'] = str(case_home)
                self.write_fixtures()
                if not first_install:
                    self.run_bootstrap()
                self.write_fixtures(extra='replacement', version='1.1.0',
                                    policy=POLICY.replace(b'@high', b'@medium'))
                source = SCRIPT.read_text()
                source = source.replace('def atomic_file(path, content):',
                    'replacements = 0\n\ndef interrupted_replace(source, target):\n'
                    '    global replacements\n    os.replace(source, target)\n'
                    '    replacements += 1\n    if replacements == ' + str(stop_after)
                    + ':\n        os._exit(73)\n\ndef atomic_file(path, content):')
                source = source.replace('os.replace(temporary, path)', 'interrupted_replace(temporary, path)')
                interrupted = self.root / ('interrupted-' + str(stop_after) + '.sh')
                interrupted.write_text(source)
                self.assertEqual(self.run_bootstrap(success=False, script=interrupted).returncode, 73)
                self.run_bootstrap()
                self.run_bootstrap()
                current = self.state() / 'current'
                self.assertTrue((current / 'pstack/skills/replacement/SKILL.md').is_file())
                self.assertFalse((current / 'pstack/skills/retired').exists())
                self.assertEqual((self.home / '.codex/pstack-models.md').read_bytes(), (current / 'pstack-models.md').read_bytes())
                self.assertIn((current / 'policy-block.md').read_bytes(), (self.home / '.codex/AGENTS.md').read_bytes())

    def test_lifetime_lock_serializes_download_and_publish(self):
        (self.fixtures / 'delay').write_text('0.15')
        first = subprocess.Popen(['sh', str(SCRIPT)], env=self.env, cwd=self.home, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        second = subprocess.Popen(['sh', str(SCRIPT)], env=self.env, cwd=self.home, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        for process in (first, second):
            output, error = process.communicate(timeout=15)
            self.assertEqual(process.returncode, 0, error.decode())
        requests = [line.split()[0] for line in (self.fixtures / 'requests').read_text().splitlines()]
        self.assertEqual(requests, ['dotfiles', 'pstack', 'dotfiles', 'pstack'])
        self.assertEqual(len(list((self.state() / 'releases').iterdir())), 1)
        self.assertEqual((self.home / '.codex/AGENTS.md').read_bytes().count(b'<!-- agent-bootstrap:start -->'), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
