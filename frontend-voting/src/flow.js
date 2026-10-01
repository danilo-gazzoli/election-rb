export class VotingFlow {
  constructor() {
    this.sessionId = null;
    this.selectedChoice = null;
    this.stageId = null;
    this.commandKey = null;
    this.warningRequired = false;
    this.lastReceiptId = null;
    this.pendingSoundReceipt = null;
    this.playedReceipts = new Set();
  }

  select(choice) {
    this.selectedChoice = { ...choice };
    this.warningRequired = false;
  }

  beginConfirmation(stageId, commandKey) {
    this.stageId = stageId;
    this.commandKey = commandKey;
  }

  intent({ acknowledgeWarning = false } = {}) {
    if (!this.selectedChoice || !this.stageId || !this.commandKey) {
      throw new Error('A voting stage and choice are required');
    }
    return {
      stage_id: this.stageId,
      command_key: this.commandKey,
      ...this.selectedChoice,
      warning_acknowledged: acknowledgeWarning
    };
  }

  acceptResponse(status, body, context) {
    if (context && (context.sessionId !== this.sessionId || context.commandKey !== this.commandKey)) {
      return 'stale';
    }
    if (status === 409 && body?.error?.code === 'choice_warning') {
      this.warningRequired = true;
      return 'warning';
    }
    if (status === 200 && body?.status === 'confirmed' && body?.receipt_id) {
      this.lastReceiptId = body.receipt_id;
      this.pendingSoundReceipt = body.receipt_id;
      this.selectedChoice = null;
      this.warningRequired = false;
      this.stageId = null;
      this.commandKey = null;
      return 'confirmed';
    }
    return status === 0 ? 'retry' : 'error';
  }

  cancelWarning() {
    this.warningRequired = false;
    this.selectedChoice = null;
  }

  clearSelection() {
    this.selectedChoice = null;
    this.stageId = null;
    this.commandKey = null;
    this.warningRequired = false;
  }

  recover({ sessionId, stageId, lastReceiptId }) {
    const identified = sessionId !== undefined;
    const newSession = identified && sessionId !== null && sessionId !== this.sessionId;
    const advanced = this.stageId !== null && this.stageId !== stageId;
    const recoveredReceipt = identified && this.sessionId !== null && !newSession && advanced &&
      this.commandKey && lastReceiptId && lastReceiptId !== this.lastReceiptId;

    if (newSession || !stageId || advanced) this.clearSelection();
    if (newSession || !stageId) this.pendingSoundReceipt = null;
    if (identified) this.sessionId = sessionId;
    if (identified || (advanced && lastReceiptId)) this.lastReceiptId = lastReceiptId ?? null;
    if (recoveredReceipt) this.pendingSoundReceipt = lastReceiptId;
  }

  panelFor(stageId) {
    if (!stageId) return 'waiting-panel';
    return this.warningRequired && this.stageId === stageId ? 'warning-panel' : 'ballot-panel';
  }

  shouldPlaySound() {
    const receipt = this.pendingSoundReceipt;
    if (!receipt || this.playedReceipts.has(receipt)) return false;

    this.pendingSoundReceipt = null;
    this.playedReceipts.add(receipt);
    return true;
  }
}
