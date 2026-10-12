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
STARTUP = (REPOSITORY / 'dotfiles/agents/cloud-startup/SKILL.md').read_bytes()
ROLES = [
    'feature, refactoring', 'bug-fix', 'perf-issue', 'hillclimb', 'judgment and prose',
    'strongest judgment', 'how explorer', 'how explainer', 'why investigators',
    'why synthesizer', 'reflect tooling', 'reflect judgment, divergent, synthesizer',
    'arena runners', 'arena cross-judge pool', 'swarm workers', 'architect runners',
    'interrogate reviewers',
]
PANELS = {'arena runners', 'arena cross-judge pool', 'architect runners', 'interrogate reviewers'}
CODEX_MAPPING = (
    b'# Codex tool mapping for pstack\n\n'
    b'| pstack / Claude action | Codex equivalent |\n'
    b'|------------------------|------------------|\n'
    b'| Read a file | `shell` (`cat`, `head`, `tail`) |\n'
    b'| Invoke a skill (the `Skill` tool, `/command`) | Skills load natively. Follow the instructions presented. |\n'
    b'| Dispatch a subagent (the `Agent`/`Task` tool) | `spawn_agent` |\n\n'
    b'Read [external guidance](https://example.com/docs) and [example path](example/project.md).\n'
    b'The native model sheet is at `$CODEX_HOME/pstack-models.md`.\n'
)
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
        'skills/poteto-mode/references/codex-tools.md': CODEX_MAPPING,
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

    def write_fixtures(self, extra='retired', version='1.0.0', policy=POLICY, files=None, malicious=None,
                       commit=None, startup=STARTUP):
        shared = {'dotfiles/agents/AGENTS.md': policy}
        if startup is not None:
            shared['dotfiles/agents/cloud-startup/SKILL.md'] = startup
        archive(self.fixtures / 'dotfiles.tgz', 'dotfiles-master', shared, 'a' * 40)
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

    def indexed_skills(self, release):
        entries = re.findall(r'^## (pstack:[a-z0-9-]+)\n\nResource: (.+)$',
                             (release / 'skills-index.md').read_text(), re.M)
        resources = {name: release / json.loads(resource) for name, resource in entries}
        self.assertEqual(len(resources), len(entries))
        for name, path in resources.items():
            self.assertTrue(path.resolve().is_relative_to(release.resolve()), name)
            self.assertTrue(path.is_file(), name)
        return resources

    def refresh_receipt_files(self, directory):
        receipt_path = directory / 'receipt.json'
        receipt = json.loads(receipt_path.read_text())
        receipt['files'] = {
            path.relative_to(directory).as_posix(): {
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'mode': path.stat().st_mode & 0o777,
            }
            for path in directory.rglob('*') if path.is_file() and path != receipt_path
        }
        receipt_path.write_text(json.dumps(receipt))
        return receipt

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

    def test_startup_source_is_retained_from_the_same_archive_and_receipt(self):
        self.run_bootstrap()
        current = self.state() / 'current'
        self.assertEqual((current / 'agent-startup/SKILL.md').read_bytes(), STARTUP)
        fetched = STARTUP + b'\nArchive-specific startup instruction.\n'
        self.write_fixtures(startup=fetched)
        self.run_bootstrap()
        skill = current / 'agent-startup/SKILL.md'
        self.assertEqual(skill.read_bytes(), fetched)
        self.assertEqual(skill.stat().st_mode & 0o777, 0o644)
        receipt = json.loads((current / 'receipt.json').read_text())
        self.assertEqual(receipt['dotfiles_commit'], 'a' * 40)
        self.assertEqual(receipt['dotfiles_archive_sha256'],
                         hashlib.sha256((self.fixtures / 'dotfiles.tgz').read_bytes()).hexdigest())
        self.assertEqual(receipt['files']['agent-startup/SKILL.md'],
                         {'sha256': hashlib.sha256(fetched).hexdigest(), 'mode': 0o644})
        before = self.snapshot()
        self.run_bootstrap()
        self.assertEqual(before, self.snapshot())
        self.assertEqual(len(list((self.state() / 'releases').iterdir())), 2)
        self.assertEqual([path.name for path in (self.home / '.agents/skills').iterdir()], ['pstack'])
        self.assertFalse((self.home / '.codex/skills').exists())

    def test_missing_empty_and_invalid_startup_sources_leave_outputs_unchanged(self):
        sources = {
            'missing': None,
            'empty': b'',
            'whitespace': b' \n\t',
            'no-frontmatter': b'Startup without metadata\n',
            'unclosed-frontmatter': b'---\nname: agent-startup\ndescription: Startup\n',
            'missing-description': b'---\nname: agent-startup\n---\nStartup\n',
            'empty-description': b'---\nname: agent-startup\ndescription:\n---\nStartup\n',
            'invalid-name': b'---\nname: [agent-startup]\ndescription: Startup\n---\nStartup\n',
            'wrong-name': b'---\nname: another-skill\ndescription: Startup\n---\nStartup\n',
            'duplicate-name': b'---\nname: agent-startup\nname: agent-startup\ndescription: Startup\n---\n',
        }
        codex = self.home / '.codex'
        codex.mkdir()
        global_agents = codex / 'AGENTS.md'
        global_agents.write_bytes(b'Keep global instructions\n')
        workspace_agents = self.home / 'AGENTS.md'
        workspace_agents.write_bytes(b'Keep workspace instructions\n')
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(self.home)
        for label, startup in sources.items():
            with self.subTest(first_install=label):
                self.write_fixtures(startup=startup)
                self.run_bootstrap(success=False)
                self.assertEqual(global_agents.read_bytes(), b'Keep global instructions\n')
                self.assertEqual(workspace_agents.read_bytes(), b'Keep workspace instructions\n')
                self.assertFalse((codex / 'pstack-models.md').exists())
                self.assertFalse((self.home / '.agents/skills/pstack').exists())
                self.assertFalse((self.state() / 'current').exists())
                self.assertEqual(list((self.state() / 'releases').iterdir()), [])
        self.write_fixtures()
        self.run_bootstrap()
        before = self.snapshot()
        workspace_before = workspace_agents.read_bytes()
        for label, startup in sources.items():
            with self.subTest(upgrade=label):
                self.write_fixtures(startup=startup)
                self.run_bootstrap(success=False)
                self.assertEqual(before, self.snapshot())
                self.assertEqual(workspace_agents.read_bytes(), workspace_before)
                self.assertEqual(len(list((self.state() / 'releases').iterdir())), 1)

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
                {'dotfiles/agents/AGENTS.md': POLICY, 'dotfiles/agents/cloud-startup/SKILL.md': STARTUP},
                'a' * 40, (member, None))
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
                         '.local/share/agent-bootstrap/current/pstack/models.json',
                         '.local/share/agent-bootstrap/current/agent-startup/SKILL.md'):
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

    def test_incomplete_required_dependencies_leave_active_release_unchanged(self):
        self.run_bootstrap()
        before = self.snapshot()
        required = (
            '.codex-plugin/plugin.json', '.claude-plugin/plugin.json', 'models.json', 'hooks/session-start-context.md',
            'skills/poteto-mode/SKILL.md', 'skills/poteto-mode/references/codex-tools.md',
            'skills/poteto-mode/playbooks/feature.md', 'skills/poteto-mode/scripts/check-playbooks.mjs',
            'skills/architect/SKILL.md', 'skills/reflect/SKILL.md',
        )
        for name, content in itertools.product(required, (None, b'', b' \r\n\t')):
            with self.subTest(name=name, content=content):
                files = package()
                path = 'plugins/pstack/' + name
                if content is None:
                    del files[path]
                else:
                    files[path] = content
                self.write_fixtures(files=files)
                result = self.run_bootstrap(success=False)
                self.assertIn('missing or empty pstack dependency: ' + name, result.stderr)
                self.assertEqual(before, self.snapshot())

    def test_codex_mapping_adapts_invocation_and_preserves_other_guidance(self):
        for ending in (b'\n', b'\r\n'):
            with self.subTest(ending=ending):
                original = CODEX_MAPPING.replace(b'\n', ending)
                files = package()
                mapping_name = 'plugins/pstack/skills/poteto-mode/references/codex-tools.md'
                files[mapping_name] = original
                self.write_fixtures(files=files)
                self.run_bootstrap()
                current = self.state() / 'current'
                resources = self.indexed_skills(current)
                mapping = resources['pstack:poteto-mode'].parent / 'references/codex-tools.md'
                adapted = mapping.read_bytes()
                upstream, fallback = adapted.split(b'\n## Retained release fallback\n\n', 1)
                invocation = rb'(?m)^\| Invoke a skill[^\r\n]+(?=\r?$)'
                self.assertEqual(re.sub(invocation, b'', upstream), re.sub(invocation, b'', original))
                self.assertIn(b'Read its full SKILL.md through the filesystem.', upstream)
                root = (mapping.resolve().parent / '../../../..').resolve()
                self.assertEqual(root, current.resolve())
                for name in ('policy-block.md', 'pstack-models.md', 'skills-index.md', 'routing.md'):
                    self.assertIn(('`' + name + '`').encode(), fallback)
                    self.assertTrue((root / name).read_bytes())
                self.assertIn(b'authoritative for every pstack role', fallback)
                before = self.snapshot()
                self.run_bootstrap()
                self.assertEqual(before, self.snapshot())
        for mapping in (b'Mapping without a skill invocation row\n', CODEX_MAPPING + CODEX_MAPPING):
            with self.subTest(mapping=mapping):
                files = package()
                files[mapping_name] = mapping
                self.write_fixtures(files=files)
                self.assertIn('expected one skill invocation row', self.run_bootstrap(success=False).stderr)
                self.assertEqual(before, self.snapshot())

    def test_rehashed_index_must_match_retained_skill_inventory(self):
        self.run_bootstrap()
        current = (self.state() / 'current').resolve()
        index_path = current / 'skills-index.md'
        original_index = index_path.read_bytes()
        receipt_path = current / 'receipt.json'
        original_receipt = receipt_path.read_bytes()
        skill = self.indexed_skills(current)['pstack:architect']
        original_skill = skill.read_bytes()
        cases = {
            'wrong-name': original_index.replace(b'## pstack:architect\n', b'## pstack:missing\n'),
            'wrong-path': original_index.replace(b'pstack/skills/architect/SKILL.md', b'pstack/skills/missing/SKILL.md'),
            'absolute-path': original_index.replace(b'pstack/skills/architect/SKILL.md', b'/tmp/outside/SKILL.md'),
            'parent-path': original_index.replace(b'pstack/skills/architect/SKILL.md', b'../../outside/SKILL.md'),
            'missing-entry': original_index.replace(original_index[original_index.index(b'## pstack:architect\n'):
                                                                  original_index.index(b'## pstack:poteto-mode\n')], b''),
            'duplicate-entry': original_index + original_index[original_index.index(b'## pstack:architect\n'):],
            'stale-metadata': original_index,
        }
        for case, changed in cases.items():
            with self.subTest(case=case):
                index_path.write_bytes(changed)
                if case == 'stale-metadata':
                    skill.write_bytes(original_skill.replace(b'Fixture skill', b'Updated workflow description'))
                self.refresh_receipt_files(current)
                before = self.snapshot()
                self.assertIn('invalid retained workspace instructions or index', self.run_bootstrap(success=False).stderr)
                self.assertEqual(before, self.snapshot())
                index_path.write_bytes(original_index)
                skill.write_bytes(original_skill)
                receipt_path.write_bytes(original_receipt)
        self.run_bootstrap()

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
        current = self.state() / 'current'
        workspace_contract = (current / 'workspace-instructions.md').read_bytes().splitlines(keepends=True)[1:-1]
        self.assertIn(b''.join(workspace_contract), (self.home / '.codex/AGENTS.md').read_bytes())
        resources = self.indexed_skills(current)
        self.assertEqual(sorted(resources), ['pstack:architect', 'pstack:poteto-mode', 'pstack:reflect', 'pstack:retired'])
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
                     b'retained files are missing', b'routing.md',
                     b'pstack/skills/poteto-mode/SKILL.md', b'pstack/skills/poteto-mode/references/codex-tools.md',
                     b'first substantive workspace answer', b'any answer about installed-skill availability',
                     b'local environment without managed setup, read the files directly',
                     b'at most 3 readiness checks', b'at most 120 seconds total', b'Limit each wait to 30 seconds',
                     b'Unrelated requests do not wait', b'leave access unverified'):
            self.assertIn(text, pointer)
        index = (current / 'skills-index.md').read_bytes()
        self.assertIn(metadata, index)
        self.assertNotIn(b'Private full skill body', index)
        resources = self.indexed_skills(current)
        self.assertEqual(sorted(resources), ['pstack:architect', 'pstack:poteto-mode', 'pstack:reflect', 'pstack:retired'])
        self.assertEqual(resources['pstack:architect'].read_bytes(), metadata + b'Private full skill body\n')
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

    def test_existing_format_two_release_upgrades_and_preserves_managed_blocks(self):
        self.env['AGENT_BOOTSTRAP_WORKSPACE'] = str(self.home)
        self.run_bootstrap()
        current = self.state() / 'current'
        directory = current.resolve()
        previous_workspace = (
            '<!-- agent-bootstrap:workspace:start -->\n'
            '# Shared agent instructions\n\n'
            'The retained installation root is the absolute path encoded by this JSON string:\n\n'
            + json.dumps(str(current)) + '\n\n'
            'At the start of substantive work, read policy-block.md, pstack-models.md, and skills-index.md from that root.\n'
            'Apply the retained policy, standing workflow routing, and model overrides.\n'
            'If the retained files are missing, report that the installation is unavailable when the task needs pstack.\n'
            'Use skills-index.md to select relevant workflows, then read their full SKILL.md files before following them.\n'
            'Read pstack/skills/poteto-mode/SKILL.md for the standing routing.\n'
            'Use these manual file reads even when the native skill catalog omits pstack or is empty.\n'
            'Resolve skill resource paths and relative references within this same release.\n'
            'The retained pstack-models.md is the authoritative override sheet for every pstack role,\n'
            'including when a skill refers to a missing or transient CODEX_HOME model sheet.\n'
            'Before project work in a child repository, read its applicable AGENTS.md and AGENTS.override.md instructions.\n'
            'Follow user instructions and applicable repository instructions.\n'
            '<!-- agent-bootstrap:workspace:end -->\n'
        ).encode()
        previous_policy = (
            b'<!-- agent-bootstrap:start -->\n' + POLICY + b'\n'
            b'Resolve pstack skill references using the available catalog identifier; '
            b'if this runtime exposes bare names, use the name without the pstack: prefix.\n'
            + package()['plugins/pstack/hooks/session-start-context.md'] + b'\n'
            b'<!-- agent-bootstrap:end -->\n'
        )
        (directory / 'workspace-instructions.md').write_bytes(previous_workspace)
        (directory / 'policy-block.md').write_bytes(previous_policy)
        (directory / 'pstack/skills/poteto-mode/references/codex-tools.md').write_bytes(CODEX_MAPPING)
        (directory / 'agent-startup/SKILL.md').unlink()
        (directory / 'agent-startup').rmdir()
        receipt = self.refresh_receipt_files(directory)
        receipt['script_sha256'] = hashlib.sha256(b'previous bootstrap version').hexdigest()
        receipt['identity'] = hashlib.sha256(('\n'.join([
            '2', receipt['dotfiles_archive_sha256'], receipt['pstack_archive_sha256'], receipt['script_sha256'],
            receipt['state'], hashlib.sha256(previous_workspace).hexdigest(),
        ])).encode()).hexdigest()
        (directory / 'receipt.json').write_text(json.dumps(receipt))
        retained = directory.with_name(receipt['identity'])
        directory.rename(retained)
        current.unlink()
        current.symlink_to('releases/' + receipt['identity'])
        global_agents = self.home / '.codex/AGENTS.md'
        workspace_agents = self.home / 'AGENTS.md'
        prefix, suffix = b'Keep user prefix\n', b'Keep user suffix\xff\n'
        global_agents.write_bytes(prefix + previous_policy + suffix)
        workspace_agents.write_bytes(prefix + previous_workspace + suffix)
        self.run_bootstrap()
        self.assertNotEqual(current.resolve(), retained)
        self.assertEqual((retained / 'policy-block.md').read_bytes(), previous_policy)
        self.assertEqual((retained / 'workspace-instructions.md').read_bytes(), previous_workspace)
        self.assertFalse((retained / 'agent-startup/SKILL.md').exists())
        self.assertEqual((current / 'agent-startup/SKILL.md').read_bytes(), STARTUP)
        self.assertEqual(global_agents.read_bytes(), prefix + (current / 'policy-block.md').read_bytes() + suffix)
        self.assertEqual(workspace_agents.read_bytes(), prefix + (current / 'workspace-instructions.md').read_bytes() + suffix)
        before = self.snapshot()
        self.run_bootstrap()
        self.assertEqual(before, self.snapshot())
        self.assertEqual(workspace_agents.read_bytes(), prefix + (current / 'workspace-instructions.md').read_bytes() + suffix)

    def test_legacy_release_upgrades_without_workspace_ownership(self):
        self.run_bootstrap()
        current = self.state() / 'current'
        directory = current.resolve()
        receipt_path = directory / 'receipt.json'
        receipt = json.loads(receipt_path.read_text())
        for name in ('workspace-instructions.md', 'skills-index.md', 'agent-startup/SKILL.md'):
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
        for content in (original.replace(b'first substantive workspace answer', b'edited workspace answer'),
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
