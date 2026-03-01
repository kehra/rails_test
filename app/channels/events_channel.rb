class EventsChannel < ApplicationCable::Channel
  def subscribed
    stream_or_reject_for current_user
  end

  def ping
    transmit({ event: "pong", received: "ok" })
  end
end
