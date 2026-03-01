require "stringio"

class Demo::ActiveSupportMiscProbe
  class EnvironmentDelegate
    delegate_missing_to :state

    def initialize(name)
      @state = ActiveSupport::StringInquirer.new(name)
    end

    private
      attr_reader :state
  end

  class DescendantParent
  end

  class DescendantChild < DescendantParent
  end

  @hook_payloads = []

  class << self
    attr_reader :hook_payloads
  end

  ActiveSupport.on_load(:teamhub_probe) do |payload|
    Demo::ActiveSupportMiscProbe.hook_payloads << payload.id
  end

  def self.transform_hash
    input = {
      "user_name" => "Alice",
      "meta" => { "request_id" => "req-1" },
      "blank" => "",
      "nil_value" => nil
    }

    compact = input.compact_blank
    symbolized = compact.deep_symbolize_keys
    transformed = symbolized.deep_transform_keys { |key| key.to_s.upcase }
    indifferent = transformed.with_indifferent_access

    {
      compact:,
      symbolized:,
      transformed:,
      indifferent:
    }
  end

  def self.with_options_result
    collector = Struct.new(:calls) do
      def record(options)
        calls << options
      end
    end.new([])

    collector.with_options(scope: :teamhub, enabled: true) do |options|
      options.record(feature: :support_probe)
    end

    collector.calls
  end

  def self.delegate_result
    EnvironmentDelegate.new("production").production?
  end

  def self.run_load_hook
    ActiveSupport.run_load_hooks(:teamhub_probe, Struct.new(:id).new(1))
    hook_payloads.dup
  end

  def self.descendant_result
    {
      descendants: DescendantParent.descendants.map(&:name),
      subclasses: DescendantParent.subclasses.map(&:name)
    }
  end

  def self.deprecation_messages
    messages = []
    deprecator = ActiveSupport::Deprecation.new("9.0", "TeamHub")
    deprecator.behavior = [ ->(message, _callstack, _deprecator) { messages << message } ]
    deprecator.warn("legacy API")
    messages
  end

  def self.broadcast_log
    primary_io = StringIO.new
    secondary_io = StringIO.new
    logger = ActiveSupport::BroadcastLogger.new(Logger.new(primary_io), Logger.new(secondary_io))
    logger.info("broadcasted")

    {
      primary: primary_io.string,
      secondary: secondary_io.string
    }
  end
end
