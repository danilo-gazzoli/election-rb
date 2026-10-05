// RealtimeTransport isolates @rails/actioncable behind a simple event API.
// Screens consume events without knowing the Action Cable protocol.

export type ChannelType = "voting-device" | "pollworker" | "public-results";

export interface RealtimeEvent {
  channel: ChannelType;
  electionId?: number;
  revision?: string;
}

export type RealtimeHandler = (event: RealtimeEvent) => void;

interface Subscription {
  channel: ChannelType;
  electionId?: number;
  handler: RealtimeHandler;
  unsubscribe: () => void;
}

let actionCableModule: typeof import("@rails/actioncable") | null = null;
let consumer: import("@rails/actioncable").Consumer | null = null;

async function getConsumer() {
  if (!consumer) {
    if (!actionCableModule) {
      actionCableModule = await import("@rails/actioncable");
    }
    consumer = actionCableModule.createConsumer("/cable");
  }
  return consumer;
}

function channelName(type: ChannelType): string {
  switch (type) {
    case "voting-device": return "VotingDeviceChannel";
    case "pollworker": return "PollworkerChannel";
    case "public-results": return "PublicResultsChannel";
  }
}

export async function subscribe(
  type: ChannelType,
  handler: RealtimeHandler,
  options?: { electionId?: number; audience?: "public" },
): Promise<Subscription> {
  const cable = await getConsumer();

  if (type === "public-results" && options?.audience === "public") {
    // Reconnect in public mode
    cable.disconnect?.();
    const mod = actionCableModule!;
    consumer = mod.createConsumer("/cable?audience=public");
  }

  const identifier = JSON.stringify({
    channel: channelName(type),
    ...(options?.electionId ? { election_id: options.electionId } : {}),
  });

  const sub = consumer.subscriptions.create(identifier, {
    received(message: Record<string, unknown>) {
      if (message.event === "state_changed") {
        handler({ channel: type, electionId: options?.electionId });
      } else if (message.event === "results_changed") {
        handler({
          channel: type,
          electionId: message.election_id as number,
          revision: message.revision as string,
        });
      }
    },
  });

  return {
    channel: type,
    electionId: options?.electionId,
    handler,
    unsubscribe: () => {
      consumer?.subscriptions.remove(sub);
    },
  };
}

export function disconnectAll(): void {
  consumer?.disconnect?.();
  consumer = null;
}
