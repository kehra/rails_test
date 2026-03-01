require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "announcement headline probe composes title into value object" do
    announcement = Demo::AnnouncementHeadlineProbe.new(title: "Release Notes")

    assert_equal "Release Notes", announcement.headline.value

    announcement.headline = "Roadmap"

    assert_equal "Roadmap", announcement.title
  end
end
