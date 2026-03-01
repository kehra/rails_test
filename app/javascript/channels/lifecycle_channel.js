import consumer from "channels/consumer"

consumer.subscriptions.create({ channel: "LifecycleChannel", allow: true }, {
  connected() {},
  disconnected() {},
  received(_data) {}
})
