module ActionPackDemoHelper
  def action_pack_badge(label)
    content_tag(:span, label, class: "action-pack-badge")
  end
end
