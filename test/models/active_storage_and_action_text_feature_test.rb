require "test_helper"

class ActiveStorageAndActionTextFeatureTest < ActiveSupport::TestCase
  test "attachment scopes options preprocessed variants and blob io APIs work" do
    user = Demo::StorageOptionUserProbe.find(users(:one).id)
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=")
    user.service_avatar.attach(io: StringIO.new(png), filename: "service.png", content_type: "image/png")
    user.service_documents.attach(
      [
        { io: StringIO.new("alpha"), filename: "alpha.txt", content_type: "text/plain" },
        { io: StringIO.new("beta"), filename: "beta.txt", content_type: "text/plain" }
      ]
    )

    loaded = Demo::StorageOptionUserProbe.with_attached_service_avatar.with_attached_service_documents.find(user.id)
    reflection = Demo::StorageOptionUserProbe.reflect_on_attachment(:service_avatar)

    assert loaded.association(:service_avatar_attachment).loaded?
    assert loaded.association(:service_documents_attachments).loaded?
    assert_equal :local, reflection.options[:service_name]
    assert_equal :purge_later, reflection.options[:dependent]
    assert_equal true, reflection.named_variants[:thumb].preprocessed
    blob_one = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("alpha"), filename: "alpha-io.txt", content_type: "text/plain")
    blob_two = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("beta"), filename: "beta-io.txt", content_type: "text/plain")

    assert_equal "alpha", blob_one.download
    assert_equal "alp", blob_one.download_chunk(0...3)
    blob_one.open do |file|
      assert_equal "alpha", file.read
    end

    composed = ActiveStorage::Blob.compose(
      [ blob_one, blob_two ],
      filename: "combined.txt",
      content_type: "text/plain"
    )

    assert_equal "alphabeta", composed.download
    assert_equal true, ActiveStorage.track_variants
    assert defined?(ActiveStorage::VariantRecord)
  end

  test "video and pdf previewer class APIs are available" do
    pdf_blob = Struct.new(:content_type) do
      def video?
        false
      end
    end.new("application/pdf")

    video_blob = Struct.new(:content_type) do
      def video?
        true
      end
    end.new("video/mp4")

    assert_includes ActiveStorage.previewers, ActiveStorage::Previewer::VideoPreviewer
    assert ActiveStorage::Previewer::PopplerPDFPreviewer.pdf?("application/pdf")
    assert ActiveStorage::Previewer::MuPDFPreviewer.pdf?("application/pdf")

    with_preview_binary_available(ActiveStorage::Previewer::VideoPreviewer, :@ffmpeg_exists) do
      assert ActiveStorage::Previewer::VideoPreviewer.accept?(video_blob)
    end

    with_preview_binary_available(ActiveStorage::Previewer::PopplerPDFPreviewer, :@pdftoppm_exists) do
      assert ActiveStorage::Previewer::PopplerPDFPreviewer.accept?(pdf_blob)
    end

    with_preview_binary_available(ActiveStorage::Previewer::MuPDFPreviewer, :@mutool_exists) do
      assert ActiveStorage::Previewer::MuPDFPreviewer.accept?(pdf_blob)
    end
  end

  test "action text attachment gallery renders gallery wrapper" do
    blob_one = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("one"), filename: "one.txt", content_type: "text/plain")
    blob_two = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("two"), filename: "two.txt", content_type: "text/plain")

    attachment_html = [
      ActionText::Attachment.from_attachable(blob_one, presentation: "gallery").to_html,
      ActionText::Attachment.from_attachable(blob_two, presentation: "gallery").to_html
    ].join
    content = ActionText::Content.new("<div>#{attachment_html}</div>")

    rendered = ApplicationController.render(
      inline: "<%= render_action_text_content(local_assigns[:content]) %>",
      locals: { content: content }
    )

    assert_includes rendered, "attachment-gallery"
    assert_includes rendered, "attachment-gallery--2"
  end

  test "direct upload controller handles error recovery in the frontend" do
    source = File.read(Rails.root.join("app/javascript/controllers/direct_upload_controller.js"))

    assert_includes source, "preventDefault()"
    assert_includes source, "Upload failed:"
    assert_includes source, "Upload complete"
  end

  test "rich text advanced APIs cover encryption plain text eager loading helpers and attachables" do
    announcement = Demo::RichContentAnnouncementProbe.create!(
      project: projects(:one),
      user: users(:one),
      title: "Rich Probe",
      body: "Body"
    )
    announcement.encrypted_summary = "<div>Secret <strong>summary</strong></div>"
    announcement.optional_notes = ""
    announcement.save!

    loaded = Demo::RichContentAnnouncementProbe.with_rich_text_encrypted_summary
      .with_rich_text_encrypted_summary_and_embeds
      .with_all_rich_text
      .find(announcement.id)

    assert loaded.association(:rich_text_encrypted_summary).loaded?
    assert_equal "Secret summary", loaded.encrypted_summary.to_plain_text.squish
    assert_nil loaded.rich_text_optional_notes

    rendered_field = ApplicationController.render(
      inline: <<~ERB,
        <%= rich_textarea_tag "post[content]", "<div>Hello</div>" %>
        <%= rich_text_area_tag "post[content_alias]", "<div>Hi</div>" %>
      ERB
    )

    assert_includes rendered_field, "trix-editor"

    attachable = Demo::RichAttachableNote.create!(
      project: projects(:one),
      user: users(:one),
      title: "Attachable",
      body: "Body"
    )

    attachment = ActionText::Attachment.from_attachable(attachable)
    content = ActionText::Content.new("<div>#{attachment.to_html}<mark data-note=\"preserve\">Marked</mark><script>alert(1)</script></div>")
    node = Nokogiri::HTML::DocumentFragment.parse(attachment.to_html).at_css("action-text-attachment")

    assert_equal attachable, ActionText::Attachable.from_attachable_sgid(attachable.attachable_sgid)
    assert_equal attachable, ActionText::Attachable.from_node(node)
    assert_includes content.attachables, attachable
    assert_includes content.to_plain_text, "[Demo::RichAttachableNote ##{attachable.id}]"
    assert_equal "demo/rich_attachable_notes/rich_attachable_note", attachable.to_attachable_partial_path
    assert_equal "demo/rich_attachable_notes/trix_rich_attachable_note", attachable.to_trix_content_attachment_partial_path
    assert_equal "demo/rich_attachable_notes/missing_rich_attachable_note", attachable.to_missing_attachable_partial_path

    rendered = ApplicationController.render(
      inline: "<%= render_action_text_content(local_assigns[:content]) %>",
      locals: { content: content }
    )

    assert_includes rendered, "rich-attachable-note"
    assert_includes rendered, "data-note=\"preserve\""
    refute_includes rendered, "<script>"
  end

  private
    def with_preview_binary_available(klass, ivar)
      previous = klass.instance_variable_defined?(ivar) ? klass.instance_variable_get(ivar) : :__unset__
      klass.instance_variable_set(ivar, true)
      yield
    ensure
      if previous == :__unset__
        klass.remove_instance_variable(ivar) if klass.instance_variable_defined?(ivar)
      else
        klass.instance_variable_set(ivar, previous)
      end
    end
end
