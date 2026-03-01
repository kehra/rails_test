class Demo::RichAttachableNote < ApplicationRecord
  self.table_name = "announcements"

  include ActionText::Attachable

  belongs_to :project
  belongs_to :user

  def to_attachable_partial_path
    "demo/rich_attachable_notes/rich_attachable_note"
  end

  def to_trix_content_attachment_partial_path
    "demo/rich_attachable_notes/trix_rich_attachable_note"
  end

  def to_missing_attachable_partial_path
    "demo/rich_attachable_notes/missing_rich_attachable_note"
  end

  def attachable_plain_text_representation(_caption = nil)
    "[Demo::RichAttachableNote ##{id}]"
  end
end
