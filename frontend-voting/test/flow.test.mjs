import assert from 'node:assert/strict';
import test from 'node:test';
import { VotingFlow } from '../src/flow.js';

test('a repetition warning never counts as a confirmed vote or plays the sound', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'nominal', candidacy_id: 12 });
  flow.beginConfirmation('stage-2', 'command-2');

  const result = flow.acceptResponse(409, { error: { code: 'choice_warning' } });
  assert.equal(result, 'warning');
  assert.equal(flow.warningRequired, true);
  assert.equal(flow.lastReceiptId, null);
  assert.equal(flow.shouldPlaySound(), false);
});

test('voter can cancel the warning and choose a different candidacy', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'nominal', candidacy_id: 12 });
  flow.beginConfirmation('stage-2', 'command-2');
  flow.acceptResponse(409, { error: { code: 'choice_warning' } });
  flow.cancelWarning();
  flow.select({ kind: 'nominal', candidacy_id: 13 });

  assert.equal(flow.warningRequired, false);
  assert.deepEqual(flow.intent(), { stage_id: 'stage-2', command_key: 'command-2',
    kind: 'nominal', candidacy_id: 13, warning_acknowledged: false });
});

test('sound is due once after a durable confirmation, including a confirmed null', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'nominal', candidacy_id: 12 });
  flow.beginConfirmation('stage-2', 'command-2');
  flow.acceptResponse(409, { error: { code: 'choice_warning' } });
  const accepted = flow.intent({ acknowledgeWarning: true });
  assert.equal(accepted.warning_acknowledged, true);

  assert.equal(flow.acceptResponse(200, { status: 'confirmed', receipt_id: 'receipt-2' }), 'confirmed');
  assert.equal(flow.shouldPlaySound(), true);
  assert.equal(flow.shouldPlaySound(), false);
  assert.equal(flow.selectedChoice, null);
});

test('lost response can retry the same command without generating a new key', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'blank' });
  flow.beginConfirmation('stage-1', 'command-1');
  const original = flow.intent();

  assert.equal(flow.acceptResponse(0, null), 'retry');
  assert.deepEqual(flow.intent(), original);
  assert.equal(flow.shouldPlaySound(), false);
});

test('server recovery clears a lost confirmation when the ballot has advanced', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'nominal', candidacy_id: 12 });
  flow.beginConfirmation('stage-1', 'command-1');
  flow.acceptResponse(0, null);

  flow.recover({ stageId: 'stage-2', lastReceiptId: 'receipt-1' });
  assert.equal(flow.selectedChoice, null);
  assert.equal(flow.commandKey, null);
  assert.equal(flow.lastReceiptId, 'receipt-1');
  assert.equal(flow.shouldPlaySound(), false);
});

test('server recovery preserves the same command while its stage remains open', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'blank' });
  flow.beginConfirmation('stage-1', 'command-1');

  flow.recover({ stageId: 'stage-1', lastReceiptId: null });
  assert.equal(flow.intent().command_key, 'command-1');
});

test('a state refresh keeps the repetition warning visible for the same stage', () => {
  const flow = new VotingFlow();
  flow.select({ kind: 'nominal', candidacy_id: 12 });
  flow.beginConfirmation('stage-2', 'command-2');
  flow.acceptResponse(409, { error: { code: 'choice_warning' } });

  assert.equal(flow.panelFor('stage-2'), 'warning-panel');
  flow.recover({ stageId: 'stage-2', lastReceiptId: 'receipt-1' });
  assert.equal(flow.panelFor('stage-2'), 'warning-panel');
});
