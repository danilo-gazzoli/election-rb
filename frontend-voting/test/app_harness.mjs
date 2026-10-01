// This harness checks app.js wiring with simulated DOM, HTTP and WebSocket.
// It is not a browser, real-server, accessibility or deployment acceptance test.
export async function loadApp({ initialState, confirm }) {
  const restorations = [];
  function install(name, value) {
    const previous = Object.getOwnPropertyDescriptor(globalThis, name);
    restorations.push(() => {
      if (previous) Object.defineProperty(globalThis, name, previous);
      else delete globalThis[name];
    });
    Object.defineProperty(globalThis, name, { configurable: true, writable: true, value });
  }

  class Element {
    constructor() {
      this.hidden = true;
      this.disabled = false;
      this.textContent = '';
      this.value = '';
      this.children = [];
      this.attributes = new Map();
      this.listeners = new Map();
    }
    setAttribute(name, value) { this.attributes.set(name, value); }
    getAttribute(name) { return this.attributes.get(name); }
    addEventListener(name, handler) { this.listeners.set(name, handler); }
    append(element) { this.children.push(element); }
    replaceChildren() { this.children = []; }
    querySelectorAll() { return this.children; }
    click() {
      if (this.disabled) return;
      return this.listeners.get('click')?.({ preventDefault() {} });
    }
  }

  const elements = new Map();
  const element = (id) => {
    if (!elements.has(id)) elements.set(id, new Element());
    return elements.get(id);
  };
  let state = initialState;
  let soundCount = 0;
  let socket = null;
  class FakeSocket {
    constructor() { socket = this; this.handlers = new Map(); }
    addEventListener(name, handler) { this.handlers.set(name, handler); }
    send() {}
    notify() {
      this.handlers.get('message')?.({ data: JSON.stringify({ message: { event: 'state_changed' } }) });
    }
  }
  class FakeAudioContext {
    constructor() { soundCount += 1; this.currentTime = 0; this.destination = {}; }
    createOscillator() {
      return { frequency: {}, connect: (target) => target, start() {}, stop() {} };
    }
    createGain() {
      return { gain: { setValueAtTime() {}, exponentialRampToValueAtTime() {} }, connect() {} };
    }
    close() {}
  }
  const requests = [];
  install('document', { getElementById: element, createElement: () => new Element() });
  install('window', { WebSocket: FakeSocket, AudioContext: FakeAudioContext,
    setInterval() {}, setTimeout() {} });
  install('location', { protocol: 'https:', host: 'school.test' });
  install('fetch', async (path, options) => {
    requests.push({ path, options });
    let result;
    if (path.endsWith('auth/session')) result = { status: 200, body: { csrf_token: 'test-csrf' } };
    else if (path.endsWith('voting-device/state')) result = { status: 200, body: state };
    else if (path.endsWith('voting-device/confirmations')) result = await confirm(JSON.parse(options.body));
    else throw new Error(`Unexpected API route: ${path}`);
    return { status: result.status, json: async () => result.body };
  });

  try {
    await import(`../src/app.js?fixture=${crypto.randomUUID()}`);
  } catch (error) {
    restorations.reverse().forEach((restore) => restore());
    throw error;
  }
  return {
    element, requests,
    soundCount: () => soundCount,
    async update(nextState) {
      state = nextState;
      socket.notify();
      await new Promise((resolve) => setImmediate(resolve));
    },
    cleanup() { restorations.reverse().forEach((restore) => restore()); }
  };
}

export function stateFor(sessionId, stageId = 2, receipt = null) {
  return { state: sessionId ? 'released' : 'locked', session_id: sessionId,
    last_receipt_id: receipt,
    stage: sessionId ? { id: stageId, contest: 'Senate', choice_index: stageId,
      candidates: [{ id: 12, number: '471', name: 'Candidate A' }] } : null };
}
