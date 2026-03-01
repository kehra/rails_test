import consumer from "channels/consumer"

consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    const liveEvents = document.getElementById("notifications_live_events")
    if (liveEvents) liveEvents.textContent = "Live notifications connected."
  },

  disconnected() {
    const liveEvents = document.getElementById("notifications_live_events")
    if (liveEvents) liveEvents.textContent = "Live notifications disconnected."
  },

  received(data) {
    const liveEvents = document.getElementById("notifications_live_events")
    if (liveEvents) liveEvents.textContent = data.message
  }
});
