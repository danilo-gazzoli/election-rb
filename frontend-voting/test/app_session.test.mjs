import assert from 'node:assert/strict';
import test from 'node:test';
import { loadApp, stateFor } from './app_harness.mjs';

test('the screen drops a repetition warning when a new session reuses the same stage', async (t) => {
  const app = await loadApp({ initialState: stateFor('session-a'),
    confirm: async () => ({ status: 409, body: { error: { code: 'choice_warning' } } }) });
  t.after(() => app.cleanup());
  app.element('choices').children[0].click();
  await app.element('confirm-button').click();
  assert.equal(app.element('warning-panel').hidden, false);

  await app.update(stateFor('session-b'));
  assert.equal(app.element('warning-panel').hidden, true);
  assert.equal(app.element('ballot-panel').hidden, false);
  assert.equal(app.element('confirm-button').disabled, true);
  assert.equal(app.soundCount(), 0);
});

test('the screen clears an unsubmitted choice when a new session reuses the same stage', async (t) => {
  const app = await loadApp({ initialState: stateFor('session-a'), confirm: async () => {
    throw new Error('No confirmation was expected');
  } });
  t.after(() => app.cleanup());
  app.element('choices').children[0].click();
  assert.equal(app.element('confirm-button').disabled, false);

  await app.update(stateFor('session-b'));
  assert.equal(app.element('confirm-button').disabled, true);
  assert.ok(app.element('choices').children.every((button) => button.getAttribute('aria-pressed') === 'false'));
});

test('the screen plays a recovered confirmation once after a lost HTTP response', async (t) => {
  const app = await loadApp({ initialState: stateFor('session-a', 1), confirm: async () => {
    throw new Error('Response lost');
  } });
  t.after(() => app.cleanup());
  app.element('choices').children[0].click();
  await app.element('confirm-button').click();
  assert.equal(app.soundCount(), 0);

  await app.update(stateFor('session-a', 2, 'receipt-a'));
  assert.equal(app.soundCount(), 1);
  await app.update(stateFor('session-a', 2, 'receipt-a'));
  assert.equal(app.soundCount(), 1);
});

test('the screen ignores a delayed confirmation from the previous session', async (t) => {
  let reply;
  const app = await loadApp({ initialState: stateFor('session-a'), confirm: () => new Promise((resolve) => {
    reply = resolve;
  }) });
  t.after(() => app.cleanup());
  app.element('choices').children[0].click();
  const pending = app.element('confirm-button').click();
  await app.update(stateFor('session-b'));
  app.element('choices').children[1].click();
  reply({ status: 200, body: { status: 'confirmed', receipt_id: 'receipt-a' } });
  await pending;

  assert.equal(app.soundCount(), 0);
  assert.equal(app.element('choices').children[1].getAttribute('aria-pressed'), 'true');
  assert.equal(app.element('confirm-button').disabled, false);
  assert.notEqual(app.element('message').textContent, 'Voto confirmado.');
  const request = app.requests.find((entry) => entry.path.endsWith('confirmations'));
  assert.equal(request.options.credentials, 'same-origin');
  assert.equal(request.options.headers['X-CSRF-Token'], 'test-csrf');
});
