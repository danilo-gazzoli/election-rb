import { VotingFlow } from './flow.js';
import { subscribeDeviceUpdates } from './device_updates.js';

const flow = new VotingFlow();
const panels = ['pair-panel', 'waiting-panel', 'ballot-panel', 'warning-panel'];
const byId = (id) => document.getElementById(id);
let currentStageId = null;
let busy = false;
let csrfToken = null;
let updatesSocket = null;
let paired = false;

function showPanel(id) {
  for (const panel of panels) byId(panel).hidden = panel !== id;
}

function message(text = '') { byId('message').textContent = text; }

async function api(path, options = {}) {
  const response = await fetch(`/api/v1/${path}`, {
    credentials: 'same-origin',
    headers: { 'Content-Type': 'application/json', ...(csrfToken ? { 'X-CSRF-Token': csrfToken } : {}) },
    ...options
  });
  const body = response.status === 204 ? null : await response.json();
  return { status: response.status, body };
}

async function ensureCsrf() {
  const { body } = await api('auth/session');
  csrfToken = body.csrf_token;
}

function makeChoice(label, choice) {
  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = label;
  button.setAttribute('aria-pressed', 'false');
  button.addEventListener('click', () => {
    flow.select(choice);
    for (const option of byId('choices').querySelectorAll('button')) {
      option.setAttribute('aria-pressed', String(option === button));
    }
    byId('confirm-button').disabled = false;
    message();
  });
  return button;
}

function showStage(stage) {
  if (stage.id === currentStageId && !byId('ballot-panel').hidden) return;
  currentStageId = stage.id;
  byId('choice-number').textContent = `Escolha ${stage.choice_index}`;
  byId('ballot-title').textContent = stage.contest;
  const choices = byId('choices');
  choices.replaceChildren();
  for (const candidate of stage.candidates) {
    choices.append(makeChoice(`${candidate.number} — ${candidate.name}`,
      { kind: 'nominal', candidacy_id: candidate.id }));
  }
  choices.append(makeChoice('Voto em branco', { kind: 'blank' }));
  choices.append(makeChoice('Voto nulo', { kind: 'null' }));
  byId('confirm-button').disabled = true;
  showPanel('ballot-panel');
}

async function refresh() {
  try {
    const { status, body } = await api('voting-device/state');
    if (status === 401) {
      paired = false;
      byId('status').textContent = 'Dispositivo sem pareamento';
      showPanel('pair-panel');
      return;
    }
    if (status !== 200) throw new Error('Não foi possível consultar o estado da votação.');
    paired = true;
    connectUpdates();
    flow.recover({ stageId: body.stage?.id ?? null, lastReceiptId: body.last_receipt_id });
    byId('status').textContent = body.state === 'locked' ? 'Dispositivo bloqueado' : 'Dispositivo liberado';
    if (body.stage && flow.panelFor(body.stage.id) === 'warning-panel') showPanel('warning-panel');
    else if (body.stage) showStage(body.stage);
    else { currentStageId = null; showPanel('waiting-panel'); }
  } catch {
    message('Conexão indisponível. Aguardando para tentar novamente.');
  }
}

function connectUpdates() {
  if (updatesSocket || !paired || !window.WebSocket) return;
  const scheme = location.protocol === 'https:' ? 'wss:' : 'ws:';
  updatesSocket = subscribeDeviceUpdates(window.WebSocket, `${scheme}//${location.host}/cable`, refresh);
  updatesSocket.addEventListener('close', () => {
    updatesSocket = null;
    window.setTimeout(connectUpdates, 3000);
  });
}

function playConfirmationSound() {
  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  if (!AudioContextClass) return;
  const context = new AudioContextClass();
  const notes = [880, 1175, 1568];
  notes.forEach((frequency, index) => {
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    const start = context.currentTime + index * 0.11;
    oscillator.type = 'sine';
    oscillator.frequency.value = frequency;
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(0.18, start + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.15);
    oscillator.connect(gain).connect(context.destination);
    oscillator.start(start);
    oscillator.stop(start + 0.16);
  });
  window.setTimeout(() => context.close(), 850);
}

async function confirm(acknowledgeWarning = false) {
  if (busy) return;
  busy = true;
  byId('confirm-button').disabled = true;
  byId('confirm-null-button').disabled = true;
  try {
    if (!flow.commandKey) flow.beginConfirmation(currentStageId, crypto.randomUUID());
    const { status, body } = await api('voting-device/confirmations', {
      method: 'POST', body: JSON.stringify(flow.intent({ acknowledgeWarning }))
    });
    const result = flow.acceptResponse(status, body);
    if (result === 'warning') {
      showPanel('warning-panel');
    } else if (result === 'confirmed') {
      if (flow.shouldPlaySound()) playConfirmationSound();
      message('Voto confirmado.');
      await refresh();
    } else {
      message(body?.error?.message || 'Não foi possível confirmar. Tente novamente.');
    }
  } catch {
    flow.acceptResponse(0, null);
    message('Resposta não recebida. Repita a confirmação; o voto não será duplicado.');
  } finally {
    busy = false;
    byId('confirm-button').disabled = !flow.selectedChoice;
    byId('confirm-null-button').disabled = false;
  }
}

byId('confirm-button').addEventListener('click', () => confirm());
byId('confirm-null-button').addEventListener('click', () => confirm(true));
byId('change-button').addEventListener('click', () => {
  flow.cancelWarning();
  showPanel('ballot-panel');
  byId('confirm-button').disabled = true;
});
byId('pair-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const pairingCode = byId('pair-code').value.trim();
  try {
    const { status } = await api('voting-device/pair', {
      method: 'POST', body: JSON.stringify({ pairing_code: pairingCode })
    });
    byId('pair-code').value = '';
    if (status !== 200) throw new Error();
    message();
    await refresh();
  } catch {
    message('Código inválido ou expirado. Peça um novo código.');
  }
});

await ensureCsrf();
await refresh();
window.setInterval(() => { if (!busy && !flow.warningRequired) refresh(); }, 3000);
