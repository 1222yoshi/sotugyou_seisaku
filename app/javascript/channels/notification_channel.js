import consumer from "./consumer"

consumer.subscriptions.create("NotificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    const action = data.action;
    if (action == 'match') {
      document.querySelector('.likes-button').classList.add('s-neon');
    } else if (action == 'new') {
      document.querySelector('.likes-button').classList.add('neon-logo-on');
    }
  }
});
