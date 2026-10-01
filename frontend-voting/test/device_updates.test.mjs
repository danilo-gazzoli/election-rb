import assert from 'node:assert/strict';
import test from 'node:test';
import { subscribeDeviceUpdates } from '../src/device_updates.js';

class FakeSocket {
  constructor() { this.handlers = new Map(); this.sent = []; }
  addEventListener(name, handler) { this.handlers.set(name, handler); }
  send(message) { this.sent.push(JSON.parse(message)); }
  emit(name, data) { this.handlers.get(name)?.({ data }); }
}

test('the device subscribes without sending a session or a vote and refreshes on state changes', () => {
  let refreshes = 0;
  const socket = subscribeDeviceUpdates(FakeSocket, 'ws://local/cable', () => { refreshes += 1; });
  socket.emit('open');

  assert.deepEqual(socket.sent, [{ command: 'subscribe',
    identifier: JSON.stringify({ channel: 'VotingDeviceChannel' }) }]);
  socket.emit('message', JSON.stringify({ message: { event: 'state_changed' } }));
  assert.equal(refreshes, 1);
});

test('the device ignores other WebSocket messages', () => {
  let refreshes = 0;
  const socket = subscribeDeviceUpdates(FakeSocket, 'ws://local/cable', () => { refreshes += 1; });
  socket.emit('message', JSON.stringify({ type: 'ping' }));
  socket.emit('message', JSON.stringify({ message: { event: 'unknown', candidacy_id: 99 } }));
  assert.equal(refreshes, 0);
});
