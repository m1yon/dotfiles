#!/bin/sh
set -eu
command -v curl >/dev/null || { echo 'agent-bootstrap: curl is required' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'agent-bootstrap: Python 3.9+ is required' >&2; exit 1; }
exec python3 - "$0" <<'PY_LOADER'
from pathlib import Path
import sys

# Large shell heredoc pipes can block before Python starts on macOS.
source = Path(sys.argv[1]).read_text(encoding='utf-8').split("\n: <<'PY_SOURCE'\n", 1)[1]
exec(compile(source.rsplit('\nPY_SOURCE', 1)[0], sys.argv[1], 'exec'))
PY_LOADER
: <<'PY_SOURCE'
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from dataclasses import dataclass
from contextlib import ExitStack
from typing import Optional

START = b'<!-- agent-bootstrap:start -->\n'
END = b'<!-- agent-bootstrap:end -->\n'
SHEET_MARKER = b'<!-- agent-bootstrap:pstack-models -->\n'
WORKSPACE_START = b'<!-- agent-bootstrap:workspace:start -->\n'
WORKSPACE_END = b'<!-- agent-bootstrap:workspace:end -->\n'
MARKER_PREFIX = b'<!-- agent-bootstrap'
FORMAT = 2
MAX_ARCHIVE = 32 * 1024 * 1024
MAX_EXPANDED = 200 * 1024 * 1024
MAX_MEMBERS = 30000
DOTFILES_URL = 'https://codeload.github.com/m1yon/dotfiles/tar.gz/refs/heads/master'
PSTACK_URL = 'https://codeload.github.com/michael-denyer/pstack-claude/tar.gz/refs/heads/main'


@dataclass(frozen=True)
class Paths:
    state: Path
    skills: Path
    codex_home: Path
    workspace: Optional[Path]


@dataclass(frozen=True)
class InstructionsPlan:
    global_agents: bytes
    workspace_agents: Optional[bytes]


@dataclass(frozen=True)
class Snapshot:
    commit: str
    archive_digest: str
    root: Path


@dataclass(frozen=True)
class Release:
    directory: Path
    identity: str
    source_skill_names: tuple[str, ...]
    namespace: str
    policy_block: bytes
    model_sheet: bytes
    workspace_block: Optional[bytes]
    receipt: dict

    @property
    def catalog_names(self):
        return tuple(self.namespace + ':' + name for name in self.source_skill_names)


def fail(message):
    raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def regular_path(path, directory=False):
    for parent in reversed((path,) + tuple(path.parents)):
        if parent.is_symlink():
            fail('refusing symlink: ' + str(parent))
        if parent.exists() and not parent.is_dir() and (parent != path or directory):
            fail('expected directory: ' + str(parent))
    if path.exists() and not directory and not path.is_file():
        fail('expected regular file: ' + str(path))


def download(url, archive, prefix, selected):
    subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                    '--proto', '=https', '--connect-timeout', '15', '--max-time', '90',
                    '--max-filesize', str(MAX_ARCHIVE), url, '-o', str(archive)], check=True)
    if archive.stat().st_size > MAX_ARCHIVE:
        fail('archive exceeds compressed size limit')
    destination = archive.with_suffix('.extracted')
    destination.mkdir()
    with tarfile.open(archive, 'r:gz') as source:
        commit = source.pax_headers.get('comment', '')
        if not re.fullmatch(r'[0-9a-f]{40}', commit):
            fail('archive lacks a full commit ID')
        seen = set()
        root = None
        size = 0
        for member in source:
            parts = member.name.rstrip('/').split('/')
            if (not parts or any(p in ('', '.', '..') for p in parts)
                    or '\\' in member.name or member.name.startswith('/')):
                fail('unsafe archive path: ' + member.name)
            if root is None:
                root = parts[0]
                if not root.startswith(prefix):
                    fail('unexpected archive root: ' + root)
            if parts[0] != root or member.name.rstrip('/') in seen:
                fail('duplicate or foreign archive path: ' + member.name)
            seen.add(member.name.rstrip('/'))
            size += member.size
            if len(seen) > MAX_MEMBERS or size > MAX_EXPANDED or member.size < 0:
                fail('archive exceeds expanded limits')
            relative = '/'.join(parts[1:])
            if not any(relative == item or relative.startswith(item + '/') for item in selected):
                continue
            if not (member.isdir() or member.isfile()):
                fail('unsupported archive member: ' + member.name)
            target = destination.joinpath(*parts[1:])
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with source.extractfile(member) as incoming, target.open('xb') as outgoing:
                    shutil.copyfileobj(incoming, outgoing)
                target.chmod(0o755 if member.mode & 0o111 else 0o644)
    return Snapshot(commit, digest(archive.read_bytes()), destination)


def skill_frontmatter(path):
    match = re.match(rb'\A---\r?\n(.*?)\r?\n---(?:\r?\n|\Z)', path.read_bytes(), re.S)
    if not match:
        fail('missing skill frontmatter: ' + str(path))
    return match[0]


def skill_name(path):
    metadata = skill_frontmatter(path).decode('utf-8')
    names = re.findall(r'^name:[ \t]*([^\r\n]+)\r?$', metadata, re.M)
    descriptions = re.findall(r'^description:[ \t]*([^\r\n]+)\r?$', metadata, re.M)
    if len(names) != 1 or len(descriptions) != 1:
        fail('ambiguous skill metadata: ' + str(path))
    name = names[0].strip()
    if len(name) > 1 and name[0] in '\"\'' and name[-1] == name[0]:
        name = name[1:-1]
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', name):
        fail('invalid skill name: ' + str(path))
    return name


def skills_index(package, namespace):
    index = (b'# Installed pstack skills\n\n'
             b'Use the complete YAML frontmatter below to select the relevant workflow.\n'
             b'Then read the selected full SKILL.md files, even when the native skill catalog is empty.\n'
             b'Resource paths are relative to this retained release. Resolve each skill\'s relative references from its directory.\n\n')
    for path in sorted((package / 'skills').rglob('SKILL.md')):
        metadata = skill_frontmatter(path)
        fence = b'`' * max(3, 1 + max((len(run) for run in re.findall(rb'`+', metadata)), default=0))
        index += ('## ' + namespace + ':' + skill_name(path) + '\n\nResource: '
                  + json.dumps('pstack/' + path.relative_to(package).as_posix()) + '\n\n').encode('utf-8')
        index += fence + b'yaml\n' + metadata + (b'' if metadata.endswith(b'\n') else b'\n') + fence + b'\n\n'
    return index


def workspace_instructions(state):
    return WORKSPACE_START + (
        '# Shared agent instructions\n\n'
        'The retained installation root is the absolute path encoded by this JSON string:\n\n'
        + json.dumps(str(state / 'current')) + '\n\n'
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
    ).encode('utf-8') + WORKSPACE_END


def catalog_name(path):
    name = skill_name(path)
    for parent in path.resolve().parents:
        for kind in ('.codex-plugin', '.claude-plugin'):
            manifest = parent / kind / 'plugin.json'
            if manifest.is_file():
                namespace = json.loads(manifest.read_text(encoding='utf-8'))['name']
                if not isinstance(namespace, str) or not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', namespace):
                    fail('invalid plugin namespace: ' + str(manifest))
                return namespace + ':' + name
    return name


def pstack_manifest(package):
    manifest = json.loads((package / '.codex-plugin/plugin.json').read_text(encoding='utf-8'))
    if (manifest['name'] != 'pstack' or Path(manifest['skills']) != Path('skills')
            or not re.fullmatch(r'\d+\.\d+\.\d+(?:[-+][a-zA-Z0-9.-]+)?', manifest['version'])):
        fail('invalid pstack Codex manifest')
    return manifest


def model_sheet(policy, models):
    sections = re.findall(r'^## pstack model configuration\n(.*?)(?=^## |\Z)', policy, re.M | re.S)
    if len(sections) != 1:
        fail('expected one canonical pstack model section')
    roles = {entry['role']: entry['models'] for entry in models['roles']}
    if (not roles or len(roles) != len(models['roles'])
            or any(kind not in ('default', 'strongest', 'panel') for kind in roles.values())):
        fail('invalid upstream role inventory')
    efforts = set(models['efforts']) | {'session'}
    rows = {}
    default = None
    started = False
    for line in sections[0].splitlines():
        if not line.strip():
            continue
        key, _, value = line.partition(': ')
        if key in roles:
            started = True
            if key in rows:
                fail('duplicate model role: ' + key)
            entries = value.split(', ')
            if roles[key] != 'panel' and len(entries) != 1:
                fail('expected one model for: ' + key)
            for entry in entries:
                match = re.fullmatch(r'([a-z][a-z0-9.-]*)(?: @([a-z]+))?', entry)
                if not match or (match[2] and match[2] not in efforts):
                    fail('invalid model or effort for: ' + key)
            rows[key] = line
        elif key == 'default effort':
            started = True
            if default is not None or value not in efforts:
                fail('invalid default effort')
            default = line
        elif started:
            fail('unknown model configuration line: ' + line)
    if set(rows) != set(roles) or default is None:
        fail('canonical policy and upstream model roles differ')
    return SHEET_MARKER + ('# pstack model configuration\n\n'
            + '\n'.join(rows[key] for key in roles) + '\n\n' + default
            + '\npanel vendors: any\n').encode('utf-8')


def file_inventory(directory):
    inventory = {}
    for path in sorted(directory.rglob('*')):
        if path.is_symlink() or not (path.is_dir() or path.is_file()):
            fail('unsupported release path: ' + str(path))
        if path.is_file() and path.relative_to(directory) != Path('receipt.json'):
            inventory[str(path.relative_to(directory))] = {
                'sha256': digest(path.read_bytes()), 'mode': path.stat().st_mode & 0o777}
    return inventory


def user_skills(directory, owned):
    visited = set()
    for root, folders, files in os.walk(directory, followlinks=True):
        path = Path(root)
        identity = (path.stat().st_dev, path.stat().st_ino)
        if identity in visited:
            folders[:] = []
            continue
        visited.add(identity)
        folders[:] = [folder for folder in folders if path / folder != owned]
        if 'SKILL.md' in files:
            yield path / 'SKILL.md'


def read_release(directory):
    regular_path(directory, directory=True)
    regular_path(directory / 'receipt.json')
    receipt = json.loads((directory / 'receipt.json').read_text(encoding='utf-8'))
    if (receipt['format'] not in (1, FORMAT) or receipt['identity'] != directory.name
            or not re.fullmatch(r'[0-9a-f]{64}', directory.name)
            or receipt['files'] != file_inventory(directory)
            or receipt['skills'] != sorted(skill_name(path) for path in (directory / 'pstack/skills').rglob('SKILL.md'))):
        fail('release validation failed: ' + str(directory))
    policy = (directory / 'policy-block.md').read_bytes()
    sheet = (directory / 'pstack-models.md').read_bytes()
    if (managed_region(policy, START, END) != (0, len(policy))
            or not sheet.startswith(SHEET_MARKER) or sheet.count(MARKER_PREFIX) != 1):
        fail('invalid retained managed output: ' + str(directory))
    manifest = pstack_manifest(directory / 'pstack')
    workspace = None
    if receipt['format'] == FORMAT:
        workspace = (directory / 'workspace-instructions.md').read_bytes()
        identity = digest(('\n'.join([str(FORMAT), receipt['dotfiles_archive_sha256'],
                                    receipt['pstack_archive_sha256'], receipt['script_sha256'],
                                    receipt['state'], digest(workspace)])).encode('utf-8'))
        if (identity != receipt['identity']
                or managed_region(workspace, WORKSPACE_START, WORKSPACE_END) != (0, len(workspace))
                or not Path(receipt['state']).is_absolute()
                or not (directory / 'skills-index.md').read_bytes()):
            fail('invalid retained workspace instructions or index: ' + str(directory))
    return Release(directory, directory.name, tuple(receipt['skills']), manifest['name'], policy, sheet, workspace, receipt)


def build_release(staging, script, state):
    shared = download(DOTFILES_URL, staging / 'dotfiles.tgz', 'dotfiles-', ['dotfiles/agents/AGENTS.md'])
    upstream = download(PSTACK_URL, staging / 'pstack.tgz', 'pstack-claude-', ['plugins/pstack', 'LICENSE'])
    directory = staging / 'release'
    directory.mkdir()
    shutil.copytree(upstream.root / 'plugins/pstack', directory / 'pstack')
    if (upstream.root / 'LICENSE').is_file():
        shutil.copy2(upstream.root / 'LICENSE', directory / 'LICENSE')
    package = directory / 'pstack'
    required = ['.codex-plugin/plugin.json', '.claude-plugin/plugin.json', 'models.json', 'hooks/session-start-context.md',
                'skills/poteto-mode/SKILL.md', 'skills/poteto-mode/references/codex-tools.md',
                'skills/poteto-mode/playbooks/feature.md', 'skills/poteto-mode/scripts/check-playbooks.mjs',
                'skills/architect/SKILL.md', 'skills/reflect/SKILL.md']
    for name in required:
        if not (package / name).is_file():
            fail('missing pstack dependency: ' + name)
    manifest = pstack_manifest(package)
    names = sorted(skill_name(path) for path in (package / 'skills').rglob('SKILL.md'))
    if len(names) != len(set(names)) or not names:
        fail('duplicate or empty pstack skill inventory')
    policy = (shared.root / 'dotfiles/agents/AGENTS.md').read_bytes()
    text = policy.decode('utf-8')
    if MARKER_PREFIX in policy:
        fail('canonical policy contains reserved ownership markers')
    sheet = model_sheet(text, json.loads((package / 'models.json').read_text(encoding='utf-8')))
    routing = (package / 'hooks/session-start-context.md').read_text(encoding='utf-8')
    if MARKER_PREFIX in routing.encode('utf-8'):
        fail('routing contains reserved ownership markers')
    references = set(re.findall(r'pstack:([a-z0-9-]+)', routing))
    if 'poteto-mode' not in references or not references.issubset(names):
        fail('routing references undiscovered pstack skills')
    resolution = ('Resolve pstack skill references using the available catalog identifier; '
                  'if this runtime exposes bare names, use the name without the pstack: prefix.\n')
    block = START + policy + b'\n' + resolution.encode('utf-8') + routing.encode('utf-8') + b'\n' + END
    workspace = workspace_instructions(state)
    script_digest = digest(script.read_bytes())
    identity = digest(('\n'.join([str(FORMAT), shared.archive_digest, upstream.archive_digest,
                                script_digest, str(state), digest(workspace)])).encode('utf-8'))
    outputs = {'shared-AGENTS.md': policy, 'routing.md': routing.encode('utf-8'),
               'policy-block.md': block, 'pstack-models.md': sheet,
               'workspace-instructions.md': workspace, 'skills-index.md': skills_index(package, manifest['name'])}
    for name, content in outputs.items():
        (directory / name).write_bytes(content)
        (directory / name).chmod(0o644)
    receipt = {'format': FORMAT, 'identity': identity, 'dotfiles_commit': shared.commit,
               'pstack_commit': upstream.commit, 'dotfiles_archive_sha256': shared.archive_digest,
               'pstack_archive_sha256': upstream.archive_digest, 'script_sha256': script_digest,
               'pstack_version': manifest['version'], 'skills': names, 'state': str(state),
               'files': file_inventory(directory)}
    (directory / 'receipt.json').write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    release = Release(directory, identity, tuple(names), manifest['name'], block, sheet, workspace, receipt)
    if sorted(catalog_name(path) for path in (package / 'skills').rglob('SKILL.md')) != list(release.catalog_names):
        fail('unexpected pstack catalog identifiers')
    return release


def managed_region(existing, start_marker, end_marker):
    if MARKER_PREFIX not in existing:
        return None
    if (existing.count(start_marker) != 1 or existing.count(end_marker) != 1
            or existing.count(MARKER_PREFIX) != 2):
        fail('malformed or foreign agent-bootstrap instruction markers')
    start = existing.index(start_marker)
    end = existing.index(end_marker) + len(end_marker)
    if start >= end - len(end_marker) or (start and existing[start - 1:start] != b'\n'):
        fail('malformed agent-bootstrap instruction markers')
    return start, end


def merge_instructions(path, block, accepted, start_marker, end_marker):
    regular_path(path)
    existing = path.read_bytes() if path.exists() else b''
    region = managed_region(existing, start_marker, end_marker)
    if region is None:
        return existing + (b'\n' if existing and not existing.endswith(b'\n') else b'') + block
    start, end = region
    if existing[start:end] not in accepted:
        fail('managed instructions were edited or have no validated release: ' + str(path))
    return existing[:start] + block + existing[end:]


def preflight(paths, release):
    for directory in (paths.skills, paths.codex_home, paths.state / 'releases'):
        regular_path(directory, directory=True)
    agents = paths.codex_home / 'AGENTS.md'
    sheet = paths.codex_home / 'pstack-models.md'
    regular_path(agents)
    regular_path(sheet)
    retained = [read_release(path) for path in sorted((paths.state / 'releases').iterdir())]
    current = paths.state / 'current'
    if os.path.lexists(current):
        if not current.is_symlink() or not re.fullmatch(r'releases/[0-9a-f]{64}', os.readlink(current)):
            fail('unowned current path: ' + str(current))
        if not any(item.directory == paths.state / os.readlink(current) for item in retained):
            fail('current points to an unvalidated release')
    link = paths.skills / 'pstack'
    expected_link = str(paths.state / 'current/pstack/skills')
    if os.path.lexists(link) and (not link.is_symlink() or os.readlink(link) != expected_link):
        fail('unowned pstack skill path: ' + str(link))
    merged = merge_instructions(agents, release.policy_block, [item.policy_block for item in retained], START, END)
    workspace = None
    if paths.workspace is not None:
        override = paths.workspace / 'AGENTS.override.md'
        regular_path(override)
        if override.exists() and override.stat().st_size:
            fail('workspace AGENTS.md is masked by nonempty override: ' + str(override))
        accepted = [item.workspace_block for item in retained
                    if item.workspace_block is not None and item.receipt['state'] == str(paths.state)]
        workspace = merge_instructions(paths.workspace / 'AGENTS.md', release.workspace_block,
                                       accepted, WORKSPACE_START, WORKSPACE_END)
    if sheet.exists() and sheet.read_bytes() not in [item.model_sheet for item in retained]:
        fail('unowned or edited model sheet: ' + str(sheet))
    for root in (paths.skills, paths.codex_home / 'skills'):
        for path in user_skills(root, link):
            if catalog_name(path) in release.catalog_names:
                fail('overlapping skill name: ' + str(path))
    return InstructionsPlan(merged, workspace)


def atomic_file(path, content):
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    descriptor, temporary = tempfile.mkstemp(prefix='.agent-bootstrap-', dir=path.parent)
    try:
        with os.fdopen(descriptor, 'wb') as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
            os.fchmod(output.fileno(), mode)
        os.replace(temporary, path)
    finally:
        if os.path.lexists(temporary):
            os.unlink(temporary)


def atomic_link(path, target):
    descriptor, temporary = tempfile.mkstemp(prefix='.agent-bootstrap-', dir=path.parent)
    os.close(descriptor)
    os.unlink(temporary)
    try:
        os.symlink(target, temporary)
        os.replace(temporary, path)
    finally:
        if os.path.lexists(temporary):
            os.unlink(temporary)


def publish(paths, release, instructions):
    destination = paths.state / 'releases' / release.identity
    if destination.exists():
        installed = read_release(destination)
        if installed.receipt != release.receipt:
            fail('existing release differs: ' + str(destination))
    else:
        os.rename(release.directory, destination)
        installed = read_release(destination)
    paths.skills.mkdir(parents=True, exist_ok=True)
    paths.codex_home.mkdir(parents=True, exist_ok=True)
    atomic_file(paths.codex_home / 'AGENTS.md', instructions.global_agents)
    atomic_file(paths.codex_home / 'pstack-models.md', release.model_sheet)
    if paths.workspace is not None:
        atomic_file(paths.workspace / 'AGENTS.md', instructions.workspace_agents)
    atomic_link(paths.skills / 'pstack', str(paths.state / 'current/pstack/skills'))
    atomic_link(paths.state / 'current', 'releases/' + release.identity)
    if ((paths.codex_home / 'AGENTS.md').read_bytes() != instructions.global_agents
            or (paths.codex_home / 'pstack-models.md').read_bytes() != release.model_sheet
            or (paths.workspace is not None
                and (paths.workspace / 'AGENTS.md').read_bytes() != instructions.workspace_agents)
            or os.readlink(paths.state / 'current') != 'releases/' + release.identity
            or sorted(catalog_name(path) for path in (paths.skills / 'pstack').rglob('SKILL.md')) != list(release.catalog_names)):
        fail('published installation verification failed')
    return installed


def workspace_path(state, skills, codex):
    value = os.environ.get('AGENT_BOOTSTRAP_WORKSPACE')
    if value is None:
        return None
    if not value or not Path(value).is_absolute():
        fail('AGENT_BOOTSTRAP_WORKSPACE must be a nonempty absolute directory path')
    regular_path(Path(value), directory=True)
    path = Path(value).resolve()
    if not path.is_dir():
        fail('workspace directory does not exist: ' + str(path))
    for owned in (state, skills, codex):
        if path == owned or owned in path.parents:
            fail('workspace aliases bootstrap state, skills, or CODEX_HOME: ' + str(path))
    return path


def main():
    if sys.version_info < (3, 9):
        fail('Python 3.9+ is required')
    home = Path(os.environ.get('AGENT_BOOTSTRAP_TARGET_HOME') or os.environ['HOME']).expanduser().absolute()
    regular_path(home, directory=True)
    home = home.resolve()
    codex = (home / '.codex' if os.environ.get('AGENT_BOOTSTRAP_TARGET_HOME') else
             Path(os.environ.get('CODEX_HOME') or home / '.codex').expanduser().absolute())
    regular_path(codex, directory=True)
    codex = codex.resolve()
    state, skills = home / '.local/share/agent-bootstrap', home / '.agents/skills'
    paths = Paths(state, skills, codex, workspace_path(state, skills, codex))
    for directory in (home, paths.state / 'releases', paths.skills, codex):
        regular_path(directory, directory=True)
    paths.state.mkdir(parents=True, exist_ok=True)
    lock = paths.state / 'install.lock'
    regular_path(lock)
    with lock.open('a+b') as handle, ExitStack() as locks:
        fcntl.flock(handle, fcntl.LOCK_EX)
        if paths.workspace is not None:
            descriptor = os.open(paths.workspace, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
            locks.callback(os.close, descriptor)
            fcntl.flock(descriptor, fcntl.LOCK_EX)
        paths.state.joinpath('releases').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='.prepare-', dir=paths.state) as private:
            release = build_release(Path(private), Path(sys.argv[1]), paths.state)
            instructions = preflight(paths, release)
            installed = publish(paths, release, instructions)
        print('agent-bootstrap: dotfiles {dotfiles_commit}; pstack {pstack_commit} '
              'v{pstack_version}; {count} skills; {directory}'.format(
                  **installed.receipt, count=len(installed.source_skill_names), directory=installed.directory))
        if paths.workspace is not None:
            print('agent-bootstrap: workspace ' + str(paths.workspace / 'AGENTS.md')
                  + '; block sha256 ' + digest(installed.workspace_block))


try:
    main()
except (ValueError, OSError, KeyError, TypeError, EOFError, tarfile.TarError, subprocess.CalledProcessError) as error:
    print('agent-bootstrap: ' + str(error), file=sys.stderr)
    sys.exit(1)
PY_SOURCE
