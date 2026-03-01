class FaultTolerantRunner
  include ActiveSupport::Rescuable

  cattr_accessor :last_handled_error, default: nil

  rescue_from StandardError do |error|
    self.class.last_handled_error = "standard:#{error.class.name}"
    :standard_error
  end

  rescue_from ArgumentError do |error|
    self.class.last_handled_error = "argument:#{error.message}"
    :argument_error
  end

  def call(mode)
    perform(mode)
  rescue => error
    rescue_with_handler(error) || raise
  end

  private
    def perform(mode)
      case mode
      when :argument
        raise ArgumentError, "invalid mode"
      when :runtime
        raise RuntimeError, "boom"
      else
        :ok
      end
    end
end
