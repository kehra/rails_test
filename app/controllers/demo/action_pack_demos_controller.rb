class Demo::ActionPackDemosController < ApplicationController
  helper ActionPackDemoHelper
  helper do
    def inline_helper_label(value)
      "inline-#{value}"
    end
  end

  def self.controller_path
    "action_pack_demos"
  end

  def token_protected
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token.to_s, "demo-token")
    end

    return if performed?

    head :ok
  end

  def token_optional
    authenticated_token = nil

    authenticate_with_http_token do |token, _options|
      authenticated_token = token if ActiveSupport::SecurityUtils.secure_compare(token.to_s, "demo-token")
    end

    render json: { authenticated: authenticated_token.present?, token: authenticated_token.presence || "none" }
  end

  def basic_optional
    username = authenticate_with_http_basic do |candidate, password|
      candidate if candidate == "basic-user" && password == "basic-secret"
    end

    render json: { authenticated: username.present?, username: username.presence || "none" }
  end

  def digest_optional
    authenticated = authenticate_with_http_digest("TeamHub") do |candidate|
      "digest-secret" if candidate == "digest-user"
    end
    username = if authenticated
      ActionController::HttpAuthentication::Digest.decode_credentials_header(request)[:username]
    end

    render json: { authenticated: !!authenticated, username: username.presence || "none" }
  end

  def request_basic_auth
    request_http_basic_authentication("Action Pack Demo")
  end

  def request_token_auth
    request_http_token_authentication("Action Pack Demo")
  end

  def request_digest_auth
    request_http_digest_authentication("Action Pack Demo")
  end

  def fallback_redirect
    redirect_back_or_to docs_preview_path
  end

  def redirect_back_demo
    redirect_back fallback_location: docs_preview_path
  end

  def cache_public
    expires_in 5.minutes, public: true
    render plain: "cache-public"
  end

  def cache_now
    expires_now
    render plain: "cache-now"
  end

  def flash_redirect
    flash[:notice] = "flash-persisted"
    redirect_to action_pack_flash_landing_path
  end

  def flash_landing
    render plain: flash[:notice].to_s.presence || "no-flash"
  end

  def flash_alert_landing
    render plain: flash[:alert].to_s.presence || "no-alert"
  end

  def flash_now_demo
    flash.now[:notice] = "flash-now"
    render plain: flash[:notice]
  end

  def flash_keep_start
    flash[:notice] = "flash-kept"
    redirect_to action_pack_flash_keep_middle_path
  end

  def flash_keep_middle
    flash.keep(:notice)
    redirect_to action_pack_flash_keep_finish_path
  end

  def flash_keep_finish
    render plain: flash[:notice].to_s.presence || "no-flash"
  end

  def redirect_notice_shortcut
    redirect_to action_pack_flash_landing_path, notice: "notice-shortcut"
  end

  def redirect_alert_shortcut
    redirect_to action_pack_flash_alert_landing_path, alert: "alert-shortcut"
  end

  def redirect_notice_status_shortcut
    redirect_to action_pack_flash_landing_path, notice: "notice-status-shortcut", status: :see_other
  end

  def redirect_alert_status_shortcut
    redirect_to action_pack_flash_alert_landing_path, alert: "alert-status-shortcut", status: :temporary_redirect
  end

  def plain_without_layout
    render plain: "plain-no-layout", layout: false
  end

  def variant_showcase
    request.variant = :phone if params[:mode] == "phone"
    render layout: false
  end

  def rendered_snippet
    html = render_to_string(partial: "summary", formats: [ :html ], locals: { title: "Action Pack", detail: "render_to_string" })
    render html: html.html_safe
  end

  def negotiated_resource
    respond_to do |format|
      format.html { render html: "<p>negotiated-html</p>".html_safe }
      format.json { render json: { format: "json", source: "action-pack-demo" } }
      format.xml { render xml: { format: "xml", source: "action-pack-demo" } }
      format.any(:text, :csv) { render plain: "negotiated-any" }
    end
  end

  def negotiated_fallback
    respond_to do |format|
      format.json { render json: { format: "json-only" } }
      format.all { head :not_acceptable, "X-Action-Pack" => "format-all" }
    end
  end

  def typed_render
    render plain: "typed-render", content_type: "text/markdown"
  end

  def partial_with_formats
    render partial: "summary", formats: [ :html ], locals: { title: "Partial Render", detail: "formats option" }
  end

  def html_without_layout
    render html: "<div>html-no-layout</div>".html_safe, layout: false, status: :accepted
  end

  def head_ready
    headers["X-Action-Pack-Head"] = "ready"
    render plain: "head-capable-body"
  end

  def frame_aware
    render json: {
      turbo_frame_request: turbo_frame_request?,
      turbo_frame_request_id: turbo_frame_request_id.to_s.presence || "none"
    }
  end

  def scoped_url_defaults_demo
    render json: {
      path: docs_preview_path,
      url: docs_preview_url
    }
  end

  def view_bridge
    badge = helpers.action_pack_badge("bridge")
    render json: {
      helpers_badge: badge,
      view_context_is_action_view_base: view_context.is_a?(ActionView::Base)
    }
  end

  def request_mutation
    request.remote_ip = "203.0.113.5"
    request.request_parameters = { "manual" => "set", "source" => "action-pack-demo" }

    render json: {
      remote_ip: request.remote_ip,
      request_parameters: request.request_parameters
    }
  end

  def request_parameter_list
    render json: {
      request_parameters_list: request.request_parameters_list
    }
  end

  def request_parameters_alias
    render json: {
      request_parameters: request.request_parameters
    }
  end

  def response_writers
    self.status = :accepted
    self.content_type = "text/plain"
    self.response_body = "writer-body"
  end

  def location_writer
    self.status = :created
    self.location = docs_about_url
    self.content_type = "text/plain"
    self.response_body = "location-writer-body"
  end

  def response_readers
    self.status = :accepted
    self.location = docs_about_url
    self.content_type = "text/plain"

    render json: {
      status: status,
      location: location,
      content_type: content_type,
      media_type: media_type
    }
  end

  def header_proxy
    headers["X-Action-Pack-Temp"] = "transient"
    deleted_header = headers["X-Action-Pack-Temp"]
    headers.delete("X-Action-Pack-Temp")
    headers["X-Action-Pack-Proxy"] = "controller-headers"
    headers["X-Action-Pack-Deleted"] = deleted_header
    self.response_body = "header-proxy-body"
  end

  def body_stream_demo
    body_value = request.body_stream.read
    request.body_stream.rewind if request.body_stream.respond_to?(:rewind)

    render json: {
      body_stream: body_value
    }
  end

  def execution_state
    before_performed = performed?
    body_value = "manual-body"
    response.set_header("X-Performed-Before", before_performed.to_s)
    response.set_header("X-Performed-After", "true")
    response.set_header("X-Response-Body", [ body_value ].inspect)
    self.response_body = body_value
    response.set_header("X-Response-Body-Reader", response_body.inspect)
  end

  def inline_render
    render inline: "<p>inline-rendered <%= 1 + 1 %></p>"
  end

  def body_render
    render body: "body-rendered"
  end

  def file_render
    render file: Rails.root.join("app/views/action_pack_demos/file_sample.html.erb"), layout: false, locals: { label: "file-rendered" }
  end

  def renderer_demo
    html = self.class.renderer.render(partial: "action_pack_demos/summary", locals: { title: "Renderer", detail: "class renderer" })
    render html: html.html_safe
  end

  def helper_panel
    @projects = Project.joins(:organization).where(organizations: { id: current_user.organization_ids }).active.order(:name)
  end

  def template_render_demo
    @template_message = "template-rendered-explicitly"
    render template: "action_pack_demos/template_render_demo"
  end

  def collection_render_demo
    @collection_items = [
      { label: "alpha" },
      { label: "beta" }
    ]

    render partial: "action_pack_demos/collection_item",
      collection: @collection_items,
      as: :item,
      layout: "action_pack_demos/collection_layout"
  end

  def turbo_helper_panel
  end

  def turbo_stream_demo
    respond_to do |format|
      format.turbo_stream do
        stream_payload = case params[:mode]
        when "morph"
          turbo_stream.replace(
            "turbo_stream_target",
            %(<div id="turbo_stream_target">turbo-stream-morph-rendered</div>).html_safe,
            method: :morph
          )
        when "refresh"
          turbo_stream.refresh(request_id: "demo-refresh")
        else
          turbo_stream.replace(
            "turbo_stream_target",
            %(<div id="turbo_stream_target">turbo-stream-rendered</div>).html_safe
          )
        end

        render turbo_stream: stream_payload
      end
      format.html { render plain: "html-fallback" }
    end
  end

  def digest_protected
    authenticate_or_request_with_http_digest("TeamHub") do |username|
      "digest-secret" if username == "digest-user"
    end

    return if performed?

    head :ok
  end

  def proc_redirect
    redirect_to proc { docs_feed_path }
  end

  def external_redirect
    redirect_to "https://example.test/outbound", allow_other_host: true
  end

  def status_redirect
    redirect_to docs_preview_path, status: :moved_permanently
  end

  def json_created
    render json: { resource: "action-pack-demo", status: "created" }, status: :created, location: docs_about_url
  end

  def request_response_details
    response.location = docs_about_url
    response.content_type = "application/json"
    response.set_header("X-Action-Pack-Temp", "temp")
    before_delete = response.get_header("X-Action-Pack-Temp")
    response.delete_header("X-Action-Pack-Temp")

    render json: {
      uuid: request.uuid,
      request_id: request.request_id,
      raw_post: request.raw_post,
      body_string: request.body.read,
      form_data: request.form_data?,
      server_software: request.server_software,
      query: request.query_parameters,
      path: request.path_parameters.slice("id", "controller", "action"),
      filtered: request.filtered_parameters.slice("visible", "token", "id"),
      authorization: request.authorization.to_s.presence || "none",
      method_symbol: request.request_method_symbol,
      media_type: request.media_type,
      ip: request.ip,
      remote_ip: request.remote_ip,
      response_location: response.location,
      response_media_type: response.media_type,
      response_status: response.status,
      response_code: response.code,
      response_message: response.message,
      response_status_message: response.status_message,
      response_content_length: response.content_length,
      response_headers: {
        content_type: response.headers["Content-Type"],
        location: response.headers["Location"]
      },
      response_header_checks: {
        has_location: response.has_header?("Location"),
        location: response.get_header("Location")
      },
      response_header_mutation: begin
        {
          before_delete:,
          after_delete: response.get_header("X-Action-Pack-Temp")
        }
      end
    }
  end

  def rendering_bridge
    @bridge_note = "assigned-through-controller"
    body = render_to_body(partial: "summary", formats: [ :html ], locals: { title: "Render To Body", detail: "bridge" })

    render json: {
      body:,
      view_assigns: view_assigns.slice("bridge_note")
    }
  end

  def request_variants
    render json: {
      xhr: request.xhr?,
      xml_http_request: request.xml_http_request?,
      format: request.format.to_s,
      get: request.get?,
      post: request.post?,
      put: request.put?,
      patch: request.patch?,
      delete: request.delete?,
      head: request.head?,
      method: request.method,
      request_method: request.request_method,
      logger_present: request.logger.present?,
      logger_matches_rails: request.logger.equal?(Rails.logger),
      content_length: request.content_length,
      host: request.host,
      host_with_port: request.host_with_port,
      base_url: request.base_url,
      protocol: request.protocol,
      port: request.port,
      ssl: request.ssl?,
      local: request.local?,
      domain: request.domain,
      subdomain: request.subdomain,
      subdomains: request.subdomains,
      referer: request.referer.to_s.presence || "none",
      user_agent: request.user_agent.to_s.presence || "none",
      custom_header: request.headers["X-Custom-Header"].to_s.presence || "none",
      path: request.path,
      path_info: request.path_info,
      script_name: request.script_name,
      url: request.url,
      original_url: request.original_url,
      fullpath: request.fullpath,
      query_string: request.query_string,
      inspect: request.inspect
    }
  end

  private

  def default_url_options
    options = super
    return options unless action_name == "scoped_url_defaults_demo"

    options.merge(section: "action_pack")
  end
end
