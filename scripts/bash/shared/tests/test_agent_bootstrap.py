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
        self.env.pop('AGENT_BOOTSTRAP_WORKSPACE', None)
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
                        b'user' + marker + end, b'<!-- agent-bootstrap:unknown -->\n',
                        b'<!-- agent-bootstrap-workspace-prototype:start -->\n'):
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
        for workspace, first_install in itertools.product((False, True), repeat=2):
            for stop_after in range(1, 6 if workspace else 5):
                with self.subTest(workspace=workspace, first_install=first_install, stop_after=stop_after):
                    self.check_interrupted_publication(workspace, first_install, stop_after)

    def check_interrupted_publication(self, workspace, first_install, stop_after):
        case_home = self.root / ('interrupted-' + str(workspace) + '-' + str(first_install) + '-' + str(stop_after))
        case_home.mkdir()
        self.home = case_home
        self.env['AGENT_BOOTSTRAP_TARGET_HOME'] = str(case_home)
        if workspace:
            self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(case_home)
        else:
            self.env.pop('AGENT_BOOTSTRAP_WORKSPACE', None)
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
        source = source.replace('# Shared agent instructions', '# Updated shared agent instructions')
        interrupted = self.root / ('interrupted-' + str(stop_after) + '.sh')
        interrupted.write_text(source)
        self.assertEqual(self.run_bootstrap(success=False, script=interrupted).returncode, 73)
        self.write_fixtures(extra='recovered', version='1.2.0')
        self.run_bootstrap()
        self.run_bootstrap()
        current = self.state() / 'current'
        self.assertTrue((current / 'pstack/skills/recovered/SKILL.md').is_file())
        self.assertFalse((current / 'pstack/skills/retired').exists())
        self.assertEqual((self.home / '.codex/pstack-models.md').read_bytes(), (current / 'pstack-models.md').read_bytes())
        self.assertIn((current / 'policy-block.md').read_bytes(), (self.home / '.codex/AGENTS.md').read_bytes())
        if workspace:
            self.assertEqual((self.home / 'AGENTS.md').read_bytes(), (current / 'workspace-instructions.md').read_bytes())

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

    def test_workspace_is_opt_in_and_omission_preserves_existing_pointer(self):
        workspace = self.root / 'workspace'
        workspace.mkdir()
        agents = workspace / 'AGENTS.md'
        agents.write_bytes(b'Workspace instructions\n')
        (self.home / 'AGENTS.md').symlink_to(agents)
        (self.home / 'AGENTS.override.md').write_bytes(b'Current directory override\n')
        self.run_bootstrap()
        self.assertEqual(agents.read_bytes(), b'Workspace instructions\n')
        self.assertTrue((self.home / 'AGENTS.md').is_symlink())
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(workspace)
        self.run_bootstrap()
        installed = agents.read_bytes()
        self.env.pop('AGENT_BOOTSTRAP_WORKSPACE')
        self.write_fixtures(extra='replacement', version='1.1.0')
        self.run_bootstrap()
        self.assertEqual(agents.read_bytes(), installed)
        other = self.root / 'other-workspace'
        other.mkdir()
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(other)
        self.run_bootstrap()
        self.assertEqual(agents.read_bytes(), installed)
        self.assertTrue((other / 'AGENTS.md').is_file())

    def test_workspace_pointer_index_and_upgrade_preserve_user_bytes(self):
        self.home = self.root / 'configured home "with quotes"'
        self.home.mkdir()
        self.env['AGENT_BOOTSTRAP_TARGET_HOME'] = str(self.home)
        transient = self.root / 'transient-codex'
        self.env['CODEX_HOME'] = str(transient)
        workspace = self.root / 'workspace'
        workspace.mkdir()
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(workspace)
        (workspace / 'AGENTS.override.md').write_bytes(b'')
        child = workspace / 'application'
        child.mkdir()
        child_agents = child / 'AGENTS.md'
        child_agents.write_bytes(b'Application instructions\r\n')
        agents = workspace / 'AGENTS.md'
        prefix, suffix = b'User prefix\r\nno final newline', b'\nUser suffix\xff'
        agents.write_bytes(prefix)
        agents.chmod(0o640)
        files = package()
        metadata = (b'---\r\nname: "architect"\r\ndescription: >-\r\n'
                    b'  Plan an interface.\r\n  Keep the complete description.\r\n'
                    b'user-invocable: false\r\n---\r\n')
        files['plugins/pstack/skills/architect/SKILL.md'] = metadata + b'Private full skill body\n'
        self.write_fixtures(files=files)
        result = self.run_bootstrap()
        self.assertIn(str(agents), result.stdout)
        current = self.state() / 'current'
        pointer = (current / 'workspace-instructions.md').read_bytes()
        self.assertIn(json.dumps(str(current)).encode(), pointer)
        for text in (b'policy-block.md', b'pstack-models.md', b'skills-index.md', b'full SKILL.md',
                     b'native skill catalog', b'authoritative override sheet', b'child repository',
                     b'retained files are missing'):
            self.assertIn(text, pointer)
        index = (current / 'skills-index.md').read_bytes()
        self.assertIn(metadata, index)
        self.assertNotIn(b'Private full skill body', index)
        for name in ('architect', 'poteto-mode', 'reflect', 'retired'):
            self.assertIn(('## pstack:' + name + '\n').encode(), index)
            self.assertIn(('pstack/skills/' + name + '/SKILL.md').encode(), index)
        receipt = json.loads((current / 'receipt.json').read_text())
        for name in ('skills-index.md', 'workspace-instructions.md'):
            self.assertEqual(receipt['files'][name]['sha256'], hashlib.sha256((current / name).read_bytes()).hexdigest())
        first = agents.read_bytes()
        self.run_bootstrap()
        self.assertEqual(agents.read_bytes(), first)
        agents.write_bytes(first + suffix)
        self.write_fixtures(extra='replacement', version='1.1.0')
        self.env['CODEX_HOME'] = str(self.root / 'another-transient-codex')
        self.run_bootstrap()
        self.assertEqual(agents.read_bytes(), prefix + b'\n' + pointer + suffix)
        self.assertEqual(agents.stat().st_mode & 0o777, 0o640)
        self.assertEqual(child_agents.read_bytes(), b'Application instructions\r\n')
        self.assertFalse(transient.exists())

    def test_legacy_release_upgrades_without_workspace_ownership(self):
        self.run_bootstrap()
        current = self.state() / 'current'
        directory = current.resolve()
        receipt_path = directory / 'receipt.json'
        receipt = json.loads(receipt_path.read_text())
        for name in ('workspace-instructions.md', 'skills-index.md'):
            (directory / name).unlink()
            del receipt['files'][name]
        receipt.pop('state')
        receipt['format'] = 1
        identity = hashlib.sha256(('\n'.join(['1', receipt['dotfiles_archive_sha256'],
                                             receipt['pstack_archive_sha256'], receipt['script_sha256']])).encode()).hexdigest()
        receipt['identity'] = identity
        receipt_path.write_text(json.dumps(receipt))
        directory.rename(directory.with_name(identity))
        current.unlink()
        current.symlink_to('releases/' + identity)
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(self.home)
        agents = self.home / 'AGENTS.md'
        agents.write_bytes(b'<!-- agent-bootstrap:workspace:start -->\nForged legacy ownership\n'
                           b'<!-- agent-bootstrap:workspace:end -->\n')
        before = self.snapshot()
        self.run_bootstrap(success=False)
        self.assertEqual(before, self.snapshot())
        agents.unlink()
        self.run_bootstrap()
        self.assertEqual(agents.read_bytes(), (current / 'workspace-instructions.md').read_bytes())
        self.assertTrue(directory.with_name(identity).is_dir())

    def test_invalid_workspace_paths_fail_without_publishing(self):
        self.run_bootstrap()
        before = self.snapshot()
        workspace = self.root / 'workspace'
        workspace.mkdir()
        linked = self.root / 'linked-workspace'
        linked.symlink_to(workspace)
        ordinary = self.root / 'ordinary-file'
        ordinary.write_bytes(b'file')
        paths = ('', '.', str(self.root / 'missing'), str(ordinary), str(linked),
                 str(linked / 'child'), str(self.home / '.codex'), str(self.home / '.agents/skills'),
                 str(self.state()), str(self.state() / 'releases'),
                 str(self.home / '.codex/../.codex'), '/' + str(self.home / '.codex'))
        for path in paths:
            with self.subTest(path=path):
                self.env['AGENT_BOOTSTRAP_WORKSPACE'] = path
                self.run_bootstrap(success=False)
                self.assertEqual(before, self.snapshot())
                self.assertFalse((workspace / 'AGENTS.md').exists())

    def test_workspace_ownership_masking_and_retained_output_conflicts(self):
        workspace = self.root / 'workspace'
        workspace.mkdir()
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(workspace)
        self.run_bootstrap()
        agents = workspace / 'AGENTS.md'
        original = agents.read_bytes()
        before = self.snapshot()
        for content in (original.replace(b'substantive work', b'edited work'),
                        original + b'<!-- agent-bootstrap:unknown -->\n',
                        original + b'<!-- agent-bootstrap-future:unknown -->\n',
                        b'<!-- agent-bootstrap-workspace-prototype:start -->\nprototype\n'
                        b'<!-- agent-bootstrap-workspace-prototype:end -->\n',
                        (self.state() / 'current/policy-block.md').read_bytes()):
            with self.subTest(content=content[:80]):
                agents.write_bytes(content)
                self.run_bootstrap(success=False)
                self.assertEqual(agents.read_bytes(), content)
                self.assertEqual(before, self.snapshot())
        agents.write_bytes(original)
        override = workspace / 'AGENTS.override.md'
        override.write_bytes(b'Masking instructions\n')
        self.assertIn('masked', self.run_bootstrap(success=False).stderr)
        override.unlink()
        agents.unlink()
        agents.symlink_to(self.home / '.codex/AGENTS.md')
        self.run_bootstrap(success=False)
        self.assertTrue(agents.is_symlink())
        agents.unlink()
        agents.mkdir()
        self.run_bootstrap(success=False)
        agents.rmdir()
        agents.write_bytes(original)
        for name in ('workspace-instructions.md', 'skills-index.md'):
            path = self.state() / 'current' / name
            saved = path.read_bytes()
            path.write_bytes(saved + b'edited\n')
            self.run_bootstrap(success=False)
            self.assertEqual(agents.read_bytes(), original)
            path.write_bytes(saved)
        self.assertEqual(before, self.snapshot())

    def test_workspace_lock_serializes_different_homes_and_refuses_foreign_owner(self):
        workspace = self.root / 'workspace'
        workspace.mkdir()
        agents = workspace / 'AGENTS.md'
        agents.write_bytes(b'Preserve user instructions\n')
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(workspace)
        second_home = self.root / 'second-home'
        second_home.mkdir()
        second_env = dict(self.env, AGENT_BOOTSTRAP_TARGET_HOME=str(second_home))
        delayed = self.root / 'delayed-publish.sh'
        source = SCRIPT.read_text().replace('instructions = preflight(paths, release)',
            'instructions = preflight(paths, release)\n            import time\n            time.sleep(0.5)')
        delayed.write_text(source)
        processes = [subprocess.Popen(['sh', str(delayed)], env=env, cwd=self.home,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                     for env in (self.env, second_env)]
        errors = []
        for process in processes:
            _, error = process.communicate(timeout=20)
            errors.append(error)
        self.assertEqual(sorted(process.returncode for process in processes), [0, 1], errors)
        winner = 0 if processes[0].returncode == 0 else 1
        homes = (self.home, second_home)
        winner_state = homes[winner] / '.local/share/agent-bootstrap/current'
        self.assertEqual(agents.read_bytes(), b'Preserve user instructions\n'
                         + (winner_state / 'workspace-instructions.md').read_bytes())
        self.assertFalse((homes[1 - winner] / '.local/share/agent-bootstrap/current').exists())
        self.assertFalse((homes[1 - winner] / '.codex/AGENTS.md').exists())

    def test_unsupported_workspace_lock_fails_before_outputs(self):
        workspace = self.root / 'workspace'
        workspace.mkdir()
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(workspace)
        unsupported = self.root / 'unsupported-lock.sh'
        unsupported.write_text(SCRIPT.read_text().replace('fcntl.flock(descriptor, fcntl.LOCK_EX)',
                                                        "raise OSError('directory locking unsupported')"))
        self.assertIn('directory locking unsupported', self.run_bootstrap(success=False, script=unsupported).stderr)
        self.assertFalse((self.state() / 'current').exists())
        self.assertFalse((workspace / 'AGENTS.md').exists())
        self.assertFalse((self.home / '.codex/AGENTS.md').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
