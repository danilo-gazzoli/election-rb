export function subscribeDeviceUpdates(WebSocketType, url, onChange) {
  const socket = new WebSocketType(url);
  socket.addEventListener('open', () => {
    socket.send(JSON.stringify({ command: 'subscribe',
      identifier: JSON.stringify({ channel: 'VotingDeviceChannel' }) }));
  });
  socket.addEventListener('message', ({ data }) => {
    try {
      const event = JSON.parse(data);
      if (event.message?.event === 'state_changed') onChange();
    } catch {
      // A malformed notification cannot change the server's voting state.
    }
  });
  return socket;
}
