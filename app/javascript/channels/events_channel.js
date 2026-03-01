import consumer from "channels/consumer"

consumer.subscriptions.create("EventsChannel", {
  connected() {
    this.perform("ping", { message: "hello" })
  },
  disconnected() {},
  received(_data) {}
})
