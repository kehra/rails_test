class Demo::AnnouncementHeadlineProbe < ApplicationRecord
  self.table_name = "announcements"

  Headline = Struct.new(:value)

  composed_of :headline,
    class_name: "Demo::AnnouncementHeadlineProbe::Headline",
    mapping: [ %w[title value] ],
    constructor: ->(value) { Headline.new(value) },
    converter: ->(value) { value.is_a?(Headline) ? value : Headline.new(value.to_s) }
end
