import copy
import json
from pathlib import Path
import tempfile
import unittest

from pstack_session_probe import REQUIRED, grade


class SessionGradeTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.release = self.root / 'release'
        self.events = [{'type': 'item.completed', 'item': {
            'type': 'mcp_tool_call', 'result': {'content': [
                {'type': 'text', 'text': json.dumps({'status': 'ready'})}]}}}]
        resources = (*REQUIRED, 'pstack/skills/architect/SKILL.md',
                     'pstack/skills/architect/references/module-boundaries.md')
        for relative in resources:
            path = self.release / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            body = 'Full body for ' + relative + '\nAdditional instructions.\n'
            path.write_text(body)
            self.events.append({'type': 'item.completed', 'item': {
                'type': 'command_execution', 'command': 'cat ' + str(path),
                'exit_code': 0, 'aggregated_output': body}})
        self.answer = {'type': 'item.completed', 'item': {
            'type': 'agent_message', 'text': 'Yes, I can access the retained skills.'}}
        self.events.extend([self.answer, {'type': 'turn.completed'}])
        self.environment([{'tool': 'environment_status', 'time': 1,
                           'result': {'status': 'ready'}}])

    def tearDown(self):
        self.directory.cleanup()

    def environment(self, records):
        (self.root / 'environment.jsonl').write_text(
            ''.join(json.dumps(record) + '\n' for record in records))

    def result(self, events=None, case='ready', code=0, arguments=()):
        return grade(events if events is not None else self.events, self.root,
                     case, [], self.release, code, arguments)['passed']

    def test_rejects_early_answer_and_incomplete_reads(self):
        self.assertTrue(self.result())
        early = [self.answer, *self.events]
        self.assertFalse(self.result(early))
        partial = copy.deepcopy(self.events)
        partial[1]['item']['aggregated_output'] = 'Full body for policy-block.md'
        self.assertFalse(self.result(partial))

    def test_requires_successful_completed_turn(self):
        self.assertTrue(self.result())
        self.assertFalse(self.result(code='timeout'))
        self.assertFalse(self.result(code=1))
        self.assertFalse(self.result(self.events[:-1]))

    def test_unverified_availability_is_not_confirmation(self):
        unverified = copy.deepcopy(self.events)
        unverified[-2]['item']['text'] = "I can't verify whether the pstack skills are available."
        self.assertFalse(self.result(unverified))
        self.assertTrue(self.result())

    def test_denied_access_is_not_confirmation(self):
        denied = copy.deepcopy(self.events)
        denied[-2]['item']['text'] = 'I do not have access to the pstack skills.'
        self.assertFalse(self.result(denied))
        self.assertTrue(self.result())

    def test_progress_prefix_cannot_hide_a_capability_answer(self):
        early = {'type': 'item.completed', 'item': {
            'type': 'agent_message',
            'text': "I'm checking the installation, but pstack is unavailable in this environment."}}
        self.assertFalse(self.result([early, *self.events]))
        self.assertTrue(self.result())

    def test_skill_text_cannot_prove_model_dispatch(self):
        self.environment([{'tool': 'environment_status', 'time': 1, 'result': {'status': 'starting'}},
                          {'tool': 'environment_status', 'time': 2, 'result': {'status': 'ready'}}])
        text_only = copy.deepcopy(self.events)
        text_only[1]['item']['aggregated_output'] += '\nspawn_agent reasoning_effort "low"'
        self.assertFalse(self.result(text_only, case='conflict'))
        self.assertFalse(self.result(case='conflict', arguments=[{
            'model': 'gpt-6-astra', 'reasoning_effort': 'xhigh'}]))
        self.assertFalse(self.result(case='conflict', arguments=[{
            'reasoning_effort': 'low', '_call_id': 'call_1', '_spawn_result': {'error': 'dispatch failed'}}]))
        self.assertTrue(self.result(case='conflict', arguments=[{
            'reasoning_effort': 'low', '_call_id': 'call_1',
            '_spawn_result': {'task_name': '/root/architect_review'}}]))


if __name__ == '__main__':
    unittest.main()
