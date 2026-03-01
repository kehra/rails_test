class Demo::RichContentAnnouncementProbe < Announcement
  has_rich_text :encrypted_summary, encrypted: true
  has_rich_text :optional_notes, store_if_blank: false
end
