class LifecycleChannel < ApplicationCable::Channel
  periodically :emit_heartbeat, every: 1.minute

  cattr_accessor :last_unsubscribed_streams, default: []

  def subscribed
    return reject unless params[:allow]

    stream_from lifecycle_stream
    stream_from decoded_stream, coder: ActiveSupport::JSON do |payload|
      transmit(payload.merge("decoded" => true), via: "decoded_stream")
    end
    stream_for current_user
  end

  def delay_confirmation
    defer_subscription_confirmation!
    send(:ensure_confirmation_sent)
    transmit({ event: "delayed_confirmation" })
  end

  def stop_named
    stop_stream_from lifecycle_stream
    transmit({ event: "stopped_named" })
  end

  def stop_decoded
    stop_stream_from decoded_stream
    transmit({ event: "stopped_decoded" })
  end

  def stop_user
    stop_stream_for current_user
    transmit({ event: "stopped_user" })
  end

  def unsubscribed
    self.class.last_unsubscribed_streams = captured_streams
    stop_all_streams
  end

  private
    def emit_heartbeat
      transmit({ event: "heartbeat" })
    end

    def lifecycle_stream
      "teamhub:lifecycle:#{current_user.id}"
    end

    def decoded_stream
      "teamhub:lifecycle:decoded:#{current_user.id}"
    end

    def captured_streams
      active_streams = send(:streams)
      active_streams.respond_to?(:keys) ? active_streams.keys : Array(active_streams)
    end
end
