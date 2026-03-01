require "test_helper"

class TurboStreamsChannelTest < ActiveSupport::TestCase
  test "signed stream names can be verified from params" do
    signed_stream_name = Turbo::StreamsChannel.signed_stream_name([ users(:one), :notifications ])
    expected_stream_name = "#{users(:one).to_gid_param}:notifications"

    probe_class = Class.new do
      include Turbo::Streams::StreamName::ClassMethods

      def self.verified_stream_name(value)
        Turbo::StreamsChannel.verified_stream_name(value)
      end

      attr_reader :params

      def initialize(params)
        @params = params
      end
    end

    assert_equal expected_stream_name, Turbo::StreamsChannel.verified_stream_name(signed_stream_name)
    assert_equal expected_stream_name, probe_class.new(signed_stream_name: signed_stream_name).verified_stream_name_from_params
  end
end
