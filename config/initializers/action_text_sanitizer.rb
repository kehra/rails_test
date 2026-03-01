ActionText::ContentHelper.allowed_tags =
  (Rails::HTML5::SafeListSanitizer.allowed_tags.to_a + %w[action-text-attachment figure figcaption sgid mark]).uniq
ActionText::ContentHelper.allowed_attributes =
  (Rails::HTML5::SafeListSanitizer.allowed_attributes.to_a + %w[sgid content-type url href filename filesize width height previewable presentation caption content data-note]).uniq
