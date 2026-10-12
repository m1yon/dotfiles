#!/usr/bin/env python3
"""Run a real fresh Codex session against an isolated managed-workspace fixture."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[3]
REQUIRED = ('agent-startup/SKILL.md', 'policy-block.md', 'pstack-models.md', 'skills-index.md', 'routing.md',
            'pstack/skills/poteto-mode/SKILL.md',
            'pstack/skills/poteto-mode/references/codex-tools.md')
PROMPTS = {
    'baseline': 'Do you have access to the pstack skills?',
    'starting': 'Do you have access to the pstack skills?',
    'ready': 'Do you have access to the pstack skills?',
    'explicit': 'Use pstack:architect to sketch the module boundaries for a small notes CLI.',
    'conflict': 'Use pstack:architect to sketch the module boundaries for a small notes CLI. Ask one architect runner to review the proposed boundaries.',
    'failure': 'Do you have access to the pstack skills?',
    'never-ready': 'Do you have access to the pstack skills?',
    'unavailable': 'Do you have access to the pstack skills?',
    'missing': 'Do you have access to the pstack skills?',
    'unrelated': 'What is 17 plus 26?',
}
SERVER = r'''import json
from pathlib import Path
import shutil
import sys
import time

root = Path(sys.argv[1])
case = sys.argv[2]
checks = 0

def publish():
    source = root / 'provisioned-instructions.md'
    target = root / 'work/AGENTS.md'
    if source.exists() and not target.exists():
        shutil.copyfile(source, target)

def record(event):
    event['time'] = time.time()
    with (root / 'environment.jsonl').open('a') as stream:
        stream.write(json.dumps(event) + '\n')

def send(identity, result):
    print(json.dumps({'jsonrpc': '2.0', 'id': identity, 'result': result}), flush=True)

for line in sys.stdin:
    request = json.loads(line)
    method = request.get('method')
    identity = request.get('id')
    if method == 'initialize':
        send(identity, {'protocolVersion': request['params']['protocolVersion'],
                        'capabilities': {'tools': {}},
                        'serverInfo': {'name': 'cloud_environment', 'version': '1.0'}})
    elif method == 'tools/list':
        send(identity, {'tools': [] if case == 'unavailable' else [
            {'name': 'environment_status', 'description': 'Return the selected managed environment status and workspace directory.', 'inputSchema': {'type': 'object', 'properties': {}}, 'annotations': {'readOnlyHint': True, 'destructiveHint': False, 'openWorldHint': False}},
            {'name': 'wait_until_ready', 'description': 'Wait for the selected managed environment to finish starting.', 'inputSchema': {'type': 'object', 'properties': {}}, 'annotations': {'readOnlyHint': True, 'destructiveHint': False, 'openWorldHint': False}},
        ]})
    elif method == 'tools/call':
        name = request['params']['name']
        checks += 1
        state = 'failed' if case == 'failure' else 'starting' if case == 'never-ready' else ('ready' if case == 'ready' or checks > 1 or name == 'wait_until_ready' else 'starting')
        if state == 'ready':
            publish()
        result = {'status': state, 'workspace': str(root / 'work')}
        if state == 'failed':
            result['message'] = 'Workspace setup exited before publishing agent instructions.'
        record({'tool': name, 'result': result})
        send(identity, {'content': [{'type': 'text', 'text': json.dumps(result)}]})
    elif identity is not None:
        send(identity, {})
'''


def toml_string(value):
    return json.dumps(str(value))


def fixture(root, bootstrap, case):
    spec = importlib.util.spec_from_file_location('bootstrap_support', HERE / 'test_agent_bootstrap.py')
    support = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(support)
    account, work, payloads = root / 'account', root / 'work', root / 'payloads'
    for path in (account, work, payloads, root / 'bin'):
        path.mkdir()
    files = support.package()
    files['plugins/pstack/skills/poteto-mode/SKILL.md'] = b'''---
name: poteto-mode
description: Standing pstack workflow routing and concise writing.
---
Read references/codex-tools.md before following pstack workflows. Read the full architect skill when the user asks to design module boundaries. Keep small read-only answers concise.
'''
    files['plugins/pstack/skills/poteto-mode/references/codex-tools.md'] = b'''| Claude Code | Codex |
| --- | --- |
| Invoke a skill (the `Skill` tool, `/command`) | Read its SKILL.md from the native catalog. |

Use local file reads to load full skills. For a requested architect runner, use the runtime's spawn_agent tool with the model and reasoning effort from the retained pstack-models.md architect runners entry. Omit the model override for inherit-parent. Do not substitute a transient model sheet.
'''
    files['plugins/pstack/skills/architect/SKILL.md'] = b'''---
name: architect
description: Design module boundaries before implementing a feature.
---
Read references/module-boundaries.md. Propose the modules for the requested program and explain which module owns persistence. If the user asks for a runner, dispatch one architect runner using the retained model override before answering.
'''
    files['plugins/pstack/skills/architect/references/module-boundaries.md'] = b'''Keep the notes domain independent of terminal input. The domain takes structured commands, persistence stores note records, and the CLI converts arguments to commands. Use these ownership boundaries when sketching a notes CLI.
'''
    policy = support.POLICY
    if case == 'conflict':
        policy = re.sub(rb'^architect runners:.*$', b'architect runners: inherit-parent @low', policy, flags=re.M)
    support.archive(payloads / 'dotfiles.tgz', 'dotfiles-master', {
        'dotfiles/agents/AGENTS.md': policy,
        'dotfiles/agents/cloud-startup/SKILL.md':
            (REPOSITORY / 'dotfiles/agents/cloud-startup/SKILL.md').read_bytes(),
    }, 'a' * 40)
    support.archive(payloads / 'pstack.tgz', 'pstack-claude-main', files, 'b' * 40)
    transport = root / 'transport.py'
    transport.write_text(support.TRANSPORT)
    curl = root / 'bin/curl'
    curl.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' + shlex.quote(str(transport)) + ' "$@"\n')
    curl.chmod(0o755)
    env = dict(os.environ, PATH=str(root / 'bin') + os.pathsep + os.environ['PATH'],
               AGENT_BOOTSTRAP_TARGET_HOME=str(account), AGENT_BOOTSTRAP_WORKSPACE=str(work),
               AGENT_BOOTSTRAP_FIXTURES=str(payloads))
    run = subprocess.run(['sh', str(bootstrap)], env=env, capture_output=True, text=True, timeout=30)
    (root / 'bootstrap.stdout').write_text(run.stdout)
    (root / 'bootstrap.stderr').write_text(run.stderr)
    if run.returncode:
        raise RuntimeError(run.stderr)
    (work / 'AGENTS.md').rename(root / 'provisioned-instructions.md')
    if case == 'ready':
        shutil.copyfile(root / 'provisioned-instructions.md', work / 'AGENTS.md')
    if case == 'missing':
        (account / '.local/share/agent-bootstrap/current/skills-index.md').unlink()
    return account, work


def grade(events, root, case, native_pstack, retained_release=None, returncode=None, dispatch_arguments=()):
    release = retained_release or (root / 'account/.local/share/agent-bootstrap/current').resolve()
    required = list(REQUIRED)
    if case in ('explicit', 'conflict'):
        required += ['pstack/skills/architect/SKILL.md',
                     'pstack/skills/architect/references/module-boundaries.md']
    ready_events = []
    for index, event in enumerate(events):
        item = event.get('item', {})
        if event.get('type') == 'item.completed' and item.get('type') == 'mcp_tool_call' and item.get('result'):
            for content in item['result'].get('content', []):
                if content.get('type') == 'text':
                    try:
                        if json.loads(content['text']).get('status') == 'ready':
                            ready_events.append(index)
                    except (json.JSONDecodeError, AttributeError):
                        pass
    reads = {}
    for index, event in enumerate(events):
        item = event.get('item', {})
        if event.get('type') != 'item.completed' or item.get('type') != 'command_execution' or item.get('exit_code') != 0:
            continue
        output = item.get('aggregated_output', '')
        for relative in required:
            path = release / relative
            if (relative not in reads and relative in item.get('command', '') and path.is_file()
                    and path.read_text().strip() in output):
                reads[relative] = {'event': index, 'command': item['command']}
    messages = [(index, event['item']['text']) for index, event in enumerate(events)
                if event.get('type') == 'item.completed' and event.get('item', {}).get('type') == 'agent_message']
    progress = re.compile(r"^(I[’']ll |I will |I[’']m (?:checking|reading|waiting|verifying|loading|using) )", re.I)
    capability_claim = re.compile(
        r"\b(?:unverified|unavailable|inaccessible|but|however)\b|"
        r"\b(?:pstack(?: skills)?|skills|installation)\s+(?:is|are)\s+(?:available|accessible)\b|"
        r"\b(?:have access|can access|cannot verify|can[’']t verify)\b", re.I)
    substantive = [(index, text) for index, text in messages
                   if index == messages[-1][0] or not progress.match(text) or capability_claim.search(text)]
    first_answer = substantive[0][0] if substantive else -1
    ordered_reads = len(reads) == len(required) and all(item['event'] < first_answer for item in reads.values())
    environment_path = root / 'environment.jsonl'
    environment = [json.loads(line) for line in environment_path.read_text().splitlines()] if environment_path.exists() else []
    states = [event['result']['status'] for event in environment]
    last = messages[-1][1] if messages else ''
    negative = bool(re.search(r"unverified|cannot verify|can[’']t verify|couldn[’']t verify|unable to verify|could not verify", last, re.I))
    checks = {'native_pstack_omitted': not native_pstack, 'cli_exited_successfully': returncode == 0,
              'turn_completed': any(event.get('type') == 'turn.completed' for event in events),
              'has_final_response': bool(messages) and any(event.get('type') == 'turn.completed' for event in events)}
    if case == 'unrelated':
        checks.update(answer_is_43=last.strip().rstrip('.') == '43', no_environment_wait=not environment)
    elif case == 'failure':
        checks.update(failed_startup_observed='failed' in states, access_reported_unverified=negative)
    elif case == 'unavailable':
        checks.update(no_readiness_tool_calls=not environment, no_retained_reads=not reads,
                      access_reported_unverified=negative,
                      unavailable_readiness_identified=bool(re.search(r'readiness|environment_status|status tool', last, re.I)))
    elif case == 'never-ready':
        checks.update(starting_observed=bool(states) and all(state == 'starting' for state in states),
                      bounded_status_checks=1 <= sum(event['tool'] == 'environment_status' for event in environment) <= 3,
                      bounded_check_duration=bool(environment) and environment[-1]['time'] - environment[0]['time'] <= 120,
                      no_retained_reads=not reads, access_reported_unverified=negative)
    elif case == 'missing':
        checks.update(ready_observed='ready' in states, access_reported_unverified=negative,
                      missing_file_identified='skills-index.md' in last,
                      failed_file_read_observed=any('skills-index.md' in item.get('command', '') and
                      re.search(r'skills-index.md[^\n]*(?:No such file|not found)', item.get('aggregated_output', ''), re.I)
                      for item in [event.get('item', {}) for event in events]))
    else:
        checks.update(ready_observed='ready' in states, retained_reads_before_answer=ordered_reads,
                      readiness_before_retained_reads=bool(ready_events) and bool(reads) and
                      min(ready_events) < min(item['event'] for item in reads.values()))
        if case != 'ready':
            checks['starting_observed'] = bool(states) and states[0] == 'starting'
        if case in ('baseline', 'starting', 'ready'):
            checks['access_confirmed'] = (
                bool(re.search(r'^\s*yes\b|\b(?:have|can) access\b', last, re.I))
                and not negative
                and not bool(re.search(r"don[’']t|do not have access|not available|no access", last, re.I)))
        if case == 'conflict':
            dispatch = [event['item'] for event in events if event.get('type') == 'item.completed'
                        and event.get('item', {}).get('type') == 'collab_tool_call'
                        and event['item'].get('tool') == 'spawn_agent'
                        and event['item'].get('status') == 'completed' and not event['item'].get('error')]
            checks['dispatch_recorded'] = bool(dispatch) or bool(dispatch_arguments)
            checks['dispatch_uses_retained_override'] = any(
                isinstance(item.get('arguments'), dict) and
                item['arguments'].get('reasoning_effort') == 'low' and
                item['arguments'].get('model') in (None, '') for item in dispatch) or any(
                    arguments.get('reasoning_effort') == 'low' and arguments.get('model') in (None, '')
                    and isinstance(arguments.get('_spawn_result'), dict)
                    and bool(arguments['_spawn_result'].get('task_name') or arguments['_spawn_result'].get('agent_id'))
                    and not arguments['_spawn_result'].get('error')
                    for arguments in dispatch_arguments)
    return {'passed': all(checks.values()), 'checks': checks, 'read_evidence': reads,
            'first_substantive_response': substantive[0][1] if substantive else None,
            'first_substantive_event': first_answer, 'environment_states': states,
            'dispatch_arguments': list(dispatch_arguments),
            'grading_limit': 'Availability and progress checks are language heuristics; inspect messages.json alongside readiness and file-read ordering. Dispatch requires structured successful tool arguments.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--case', choices=PROMPTS, required=True)
    parser.add_argument('--bootstrap', type=Path)
    parser.add_argument('--baseline-ref', default='HEAD', help='Git revision used by the baseline case when --bootstrap is omitted.')
    parser.add_argument('--startup-skill', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--retained-release', type=Path, help='Use an existing real retained release without copying or modifying it.')
    parser.add_argument('--timeout', type=int, default=240)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    root = Path(tempfile.mkdtemp(prefix='cedar-')).resolve()
    bootstrap = args.bootstrap or HERE.parent / 'agent-bootstrap.sh'
    if args.case == 'baseline' and args.bootstrap is None:
        bootstrap = args.output / 'baseline-agent-bootstrap.sh'
        original = subprocess.run(['git', 'show', args.baseline_ref + ':scripts/bash/shared/agent-bootstrap.sh'],
                                  cwd=REPOSITORY, capture_output=True, check=True)
        bootstrap.write_bytes(original.stdout)
    if args.retained_release:
        if args.case not in ('starting', 'ready', 'baseline'):
            parser.error('--retained-release supports availability scenarios only')
        args.retained_release = args.retained_release.resolve()
        account, work = root / 'account', root / 'work'
        account.mkdir()
        work.mkdir()
        shutil.copyfile(args.retained_release / 'workspace-instructions.md', root / 'provisioned-instructions.md')
        if args.case == 'ready':
            shutil.copyfile(root / 'provisioned-instructions.md', work / 'AGENTS.md')
    else:
        account, work = fixture(root, bootstrap.resolve(), args.case)
    cli_home = root / 'client'
    cli_home.mkdir()
    auth = Path(os.environ.get('CODEX_HOME', str(Path.home() / '.codex'))) / 'auth.json'
    if not auth.is_file():
        raise RuntimeError('Codex auth.json is unavailable; no credentials were inspected.')
    (cli_home / 'auth.json').symlink_to(auth)
    runtime = cli_home / 'skills/cloud-environment-runtime/SKILL.md'
    runtime.parent.mkdir(parents=True)
    shutil.copyfile(args.startup_skill, runtime)
    if args.case == 'conflict':
        (cli_home / 'pstack-models.md').write_text('architect runners: gpt-6-astra @xhigh\n')
    server = root / 'runtime.py'
    server.write_text(SERVER)
    state = 'ready' if args.case == 'ready' else 'starting'
    context = 'This task uses a managed cloud environment. The selected environment is ' + state + '. Its workspace is ' + str(work) + '.'
    overrides = [
        'developer_instructions=' + toml_string(context),
        'mcp_servers.cloud_environment.command=' + toml_string(sys.executable),
        'mcp_servers.cloud_environment.args=' + json.dumps([str(server), str(root), args.case]),
        'mcp_servers.cloud_environment.required=true',
        'features.multi_agent=true',
    ]
    config = [value for item in overrides for value in ('-c', item)]
    env = dict(os.environ, CODEX_HOME=str(cli_home))
    prompt = PROMPTS[args.case]
    debug = subprocess.run(['codex', 'debug', 'prompt-input', *config, prompt], cwd=work, env=env,
                           capture_output=True, text=True, timeout=30)
    (args.output / 'prompt-input.json').write_text(debug.stdout)
    (args.output / 'prompt-input.stderr').write_text(debug.stderr)
    def strings(value):
        if isinstance(value, str):
            yield value
        elif isinstance(value, list):
            for item in value:
                yield from strings(item)
        elif isinstance(value, dict):
            for item in value.values():
                yield from strings(item)
    prompt_text = '\n'.join(strings(json.loads(debug.stdout)))
    native_pstack = re.findall(r'(?m)^- pstack:[^\n]+', prompt_text)
    if native_pstack:
        raise RuntimeError('Native pstack catalog unexpectedly present.')
    command = ['codex', 'exec', '--json', *([] if args.case == 'conflict' else ['--ephemeral']), '--ignore-user-config', '--skip-git-repo-check',
               '-s', 'read-only', *config, prompt]
    started = time.time()
    with (args.output / 'events.jsonl').open('w') as stdout, (args.output / 'stderr.txt').open('w') as stderr:
        process = subprocess.Popen(command, cwd=work, env=env, stdout=stdout, stderr=stderr, stdin=subprocess.DEVNULL)
        try:
            code = process.wait(timeout=min(args.timeout, 180) if args.case == 'never-ready' else args.timeout)
        except subprocess.TimeoutExpired:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            code = 'timeout'
    events = []
    for line in (args.output / 'events.jsonl').read_text().splitlines():
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            pass
    messages = [event['item']['text'] for event in events if event.get('type') == 'item.completed'
                and event.get('item', {}).get('type') == 'agent_message']
    completed = [event['item'] for event in events if event.get('type') == 'item.completed'
                 and event.get('item', {}).get('type') == 'command_execution']
    evidence = [{'command': item.get('command'), 'exit_code': item.get('exit_code'),
                 'output': item.get('aggregated_output', '')} for item in completed]
    environment = root / 'environment.jsonl'
    if environment.exists():
        shutil.copyfile(environment, args.output / 'environment.jsonl')
    for name in ('bootstrap.stdout', 'bootstrap.stderr'):
        if (root / name).exists():
            shutil.copyfile(root / name, args.output / name)
    (args.output / 'messages.json').write_text(json.dumps(messages, indent=2) + '\n')
    (args.output / 'commands.json').write_text(json.dumps(evidence, indent=2) + '\n')
    dispatch_arguments = []
    thread_id = next((event['thread_id'] for event in events if event.get('type') == 'thread.started'), None)
    if thread_id:
        for rollout in (cli_home / 'sessions').rglob('*' + thread_id + '.jsonl'):
            records = [json.loads(line) for line in rollout.read_text().splitlines()]
            if not any(record.get('type') == 'session_meta' and record.get('payload', {}).get('id') == thread_id for record in records):
                continue
            outputs = {record['payload']['call_id']: record['payload']['output'] for record in records
                       if record.get('type') == 'response_item' and record.get('payload', {}).get('type') == 'function_call_output'}
            for record in records:
                payload = record.get('payload', {})
                if record.get('type') == 'response_item' and payload.get('type') == 'function_call' and payload.get('name', '').split('.')[-1] == 'spawn_agent':
                    arguments = json.loads(payload['arguments'])
                    evidence = {key: arguments[key] for key in ('task_name', 'model', 'reasoning_effort', 'fork_turns') if key in arguments}
                    evidence['_call_id'] = payload['call_id']
                    try:
                        evidence['_spawn_result'] = json.loads(outputs.get(payload['call_id'], 'null'))
                    except json.JSONDecodeError:
                        evidence['_spawn_result'] = None
                    dispatch_arguments.append(evidence)
    (args.output / 'dispatch-arguments.json').write_text(json.dumps(dispatch_arguments, indent=2) + '\n')
    verdict = grade(events, root, args.case, native_pstack, args.retained_release, code, dispatch_arguments)
    (args.output / 'grade.json').write_text(json.dumps(verdict, indent=2) + '\n')
    summary = {'grade': verdict, 'parent_thread_id': thread_id, 'case': args.case, 'returncode': code, 'elapsed_seconds': round(time.time() - started, 2),
               'fixture_root': str(root), 'bootstrap_sha256': hashlib.sha256(bootstrap.read_bytes()).hexdigest(),
               'startup_sha256': hashlib.sha256(args.startup_skill.read_bytes()).hexdigest(),
               'native_catalog_verified_by': 'prompt-input.json; review Available skills entries',
               'first_response': messages[0] if messages else None, 'final_response': messages[-1] if messages else None,
               'required_reads': list(REQUIRED),
               'retained_release': str(args.retained_release) if args.retained_release else None,
               'limitation': 'Local controlled readiness. Does not prove production host injection. ' + ('Actual retained skill package.' if args.retained_release else 'Controlled fixture skill package.')}
    (args.output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    (cli_home / 'auth.json').unlink()
    print(json.dumps({'case': args.case, 'passed': verdict['passed'], 'checks': verdict['checks'],
                      'final_response': summary['final_response'], 'artifacts': str(args.output)}, indent=2))
    return 0 if verdict['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
