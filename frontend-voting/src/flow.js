export class VotingFlow {
  constructor() {
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

  acceptResponse(status, body) {
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

  recover({ stageId, lastReceiptId }) {
    if (this.stageId && this.stageId !== stageId && lastReceiptId) {
      this.selectedChoice = null;
      this.stageId = null;
      this.commandKey = null;
      this.warningRequired = false;
      this.lastReceiptId = lastReceiptId;
    }
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
