class AdvancedMailer < ApplicationMailer
  cattr_accessor :callback_log, default: []

  default to: -> { params[:recipient].presence || "fallback@example.test" },
          from: -> { email_address_with_name("robot@example.test", "TeamHub Robot") }

  after_action :apply_mail_headers
  around_action :track_action_callback
  around_deliver :track_delivery_callback

  def digest_report
    attachments["summary.txt"] = "summary=#{params[:label].presence || 'none'}"
    attachments.inline["pixel.txt"] = "inline-pixel"
    headers["X-Trace-Token"] = params[:trace].to_s
    headers("X-Workflow" => "advanced-mailer")

    mail(subject: params[:subject].presence || default_i18n_subject(app: "TeamHub")) do |format|
      format.text { render plain: text_body }
      format.html { render html: html_body.html_safe }
    end
  end

  def default_url_options
    ActionMailer::Base.default_url_options.merge(host: "mailer.example.test")
  end

  private
    def apply_mail_headers
      headers["X-After-Action"] = "ran"
    end

    def track_action_callback
      self.class.callback_log << :around_action_before
      yield
      self.class.callback_log << :around_action_after
    end

    def track_delivery_callback
      self.class.callback_log << :around_deliver_before
      yield
      self.class.callback_log << :around_deliver_after
    end

    def text_body
      [
        "Digest for #{params[:recipient_name].presence || 'reader'}",
        (project_url(params[:project]) if params[:project])
      ].compact.join("\n")
    end

    def html_body
      <<~HTML
        <p>Digest for #{ERB::Util.html_escape(params[:recipient_name].presence || "reader")}</p>
        <p>#{ERB::Util.html_escape(project_url(params[:project])) if params[:project]}</p>
        <img src="#{attachments["pixel.txt"].url}" alt="pixel">
      HTML
    end
end
