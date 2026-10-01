import assert from 'node:assert/strict';
import test from 'node:test';
import { VotingFlow } from '../src/flow.js';

function pendingFlow() {
  const flow = new VotingFlow();
  flow.recover({ sessionId: 'session-a', stageId: 'stage-2', lastReceiptId: null });
  flow.select({ kind: 'nominal', candidacy_id: 12 });
  flow.beginConfirmation('stage-2', 'command-a');
  return flow;
}

function assertCleared(flow) {
  assert.equal(flow.selectedChoice, null);
  assert.equal(flow.commandKey, null);
  assert.equal(flow.stageId, null);
  assert.equal(flow.warningRequired, false);
}

test('locking clears an unsubmitted selection even without a receipt', () => {
  const flow = new VotingFlow();
  flow.recover({ sessionId: 'session-a', stageId: 'stage-1', lastReceiptId: null });
  flow.select({ kind: 'blank' });

  flow.recover({ sessionId: null, stageId: null, lastReceiptId: null });
  assertCleared(flow);
  assert.equal(flow.shouldPlaySound(), false);
});

test('abandonment clears a warning and pending command without a receipt', () => {
  const flow = pendingFlow();
  flow.acceptResponse(409, { error: { code: 'choice_warning' } });

  flow.recover({ sessionId: null, stageId: null, lastReceiptId: null });
  assertCleared(flow);
  assert.equal(flow.panelFor(null), 'waiting-panel');
  assert.equal(flow.shouldPlaySound(), false);
});

test('a new session clears the previous warning even when the stage id is reused', () => {
  const flow = pendingFlow();
  flow.acceptResponse(409, { error: { code: 'choice_warning' } });

  flow.recover({ sessionId: 'session-b', stageId: 'stage-2', lastReceiptId: null });
  assertCleared(flow);
  assert.equal(flow.sessionId, 'session-b');
  assert.equal(flow.panelFor('stage-2'), 'ballot-panel');
});

test('refreshing the same session and stage preserves a pending retry', () => {
  const flow = pendingFlow();
  const intent = flow.intent();

  flow.recover({ sessionId: 'session-a', stageId: 'stage-2', lastReceiptId: null });
  assert.deepEqual(flow.intent(), intent);
});

test('a late receipt from the previous session cannot clear the next voter selection', () => {
  const flow = pendingFlow();
  flow.recover({ sessionId: 'session-b', stageId: 'stage-2', lastReceiptId: null });
  flow.select({ kind: 'blank' });

  const result = flow.acceptResponse(200, { status: 'confirmed', receipt_id: 'receipt-a' },
    { sessionId: 'session-a', commandKey: 'command-a' });
  assert.equal(result, 'stale');
  assert.deepEqual(flow.selectedChoice, { kind: 'blank' });
  assert.equal(flow.lastReceiptId, null);
  assert.equal(flow.shouldPlaySound(), false);
});

test('a durable recovered receipt in the same session produces sound once', () => {
  const flow = pendingFlow();
  flow.acceptResponse(0, null);

  flow.recover({ sessionId: 'session-a', stageId: 'stage-3', lastReceiptId: 'receipt-a' });
  assertCleared(flow);
  assert.equal(flow.lastReceiptId, 'receipt-a');
  assert.equal(flow.shouldPlaySound(), true);
  flow.recover({ sessionId: 'session-a', stageId: 'stage-3', lastReceiptId: 'receipt-a' });
  assert.equal(flow.shouldPlaySound(), false);
});

test('a final recovered receipt can produce sound after the device locks', () => {
  const flow = pendingFlow();
  flow.acceptResponse(0, null);

  flow.recover({ sessionId: null, stageId: null, lastReceiptId: 'receipt-a' });
  assertCleared(flow);
  assert.equal(flow.shouldPlaySound(), true);
  assert.equal(flow.shouldPlaySound(), false);
});
