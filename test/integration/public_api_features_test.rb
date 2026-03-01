require "test_helper"

class PublicApiFeaturesTest < ActionDispatch::IntegrationTest
  setup do
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "direct route helper points to docs preview" do
    assert_equal "/docs/preview", help_center_path
  end

  test "markdown rendering endpoint responds" do
    get docs_preview_url
    assert_response :success
    assert_includes response.body, "TeamHub API Notes"
  end

  test "rack app mount responds" do
    get "/rack_echo"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "rack_echo"
  end

  test "api controller based on ActionController::API responds" do
    get "/api/ping"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"ok\":true"
  end

  test "api controller based on ActionController::Metal responds" do
    get "/api/metal_ping"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"via\":\"metal\""
    assert_includes response.body, "\"status\":200"
    assert_includes response.body, "\"location\":\"/docs/about\""
    assert_includes response.body, "\"content_type\":\"application/json; charset=utf-8\""
    assert_includes response.body, "\"media_type\":\"application/json\""
    assert_includes response.body, "\"header\":\"true\""
    assert_includes response.body, "\"deleted_header\":\"transient\""
    assert_includes response.body, "\"temp_header_present\":false"
    assert_includes response.body, "\"response_body_class\":\"Array\""
    assert_includes response.body, "\"response_body_length\":1"
    assert_equal "/docs/about", response.headers["Location"]
    assert_nil response.headers["X-Metal-Temp"]
    assert_equal "true", response.headers["X-Metal-Ping"]
  end

  test "send_stream endpoint responds" do
    get stream_tasks_url
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "id,title,status"
  end

  test "send_file endpoint uses x-sendfile header" do
    get export_file_tasks_url
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match %r{/tmp/tasks-.*\.csv}, response.headers["X-Sendfile"]
    assert_equal "0", response.headers["Content-Length"]
  end

  test "mounted sample engine route responds" do
    get "/engine/status"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"engine\":\"teamhub_sample_engine\""
  end

  test "middleware insertion adds chain header in configured order" do
    get "/docs/about"
    assert_response :success
    assert_equal "marker,audit", response.headers["X-TeamHub-Middleware"]
  end

  test "etag endpoint returns not_modified when if-modified-since is sent" do
    get "/docs/etag"
    assert_response :success

    last_modified = response.headers["Last-Modified"]
    get "/docs/etag", headers: { "If-Modified-Since" => last_modified }
    assert_response :not_modified
  end

  test "defaults format route responds json without extension" do
    get "/docs/about"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"name\":\"TeamHub\""
  end

  test "atom builder route responds with atom feed" do
    get "/docs/feed"
    assert_response :success
    assert_equal "application/atom+xml", response.media_type
    assert_includes response.body, "<feed"
    assert_includes response.body, "TeamHub Tasks"
  end

  test "debug helper route renders debug_dump helper output" do
    get "/docs/debug_dump"
    assert_response :success
    assert_includes response.body, "debug_dump"
    assert_includes response.body, "docs#debug_dump"
  end

  test "glob route captures file path segment" do
    get "/docs/files/guides/routing/advanced"
    assert_response :success
    assert_includes response.body, "guides/routing/advanced"
  end

  test "path_names scoped route for localized projects exists" do
    get "/localized_projects/neu"
    assert_response :success
  end

  test "shallow_path and shallow_prefix route helpers are available" do
    path = c_audit_comment_path(comments(:one))

    assert_equal "/c/audit_comments/#{comments(:one).id}", path
  end

  test "http basic auth protects admin diagnostics" do
    get "/admin/diagnostics"
    assert_response :unauthorized

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret")
    get "/admin/diagnostics", headers: { "HTTP_AUTHORIZATION" => credentials }
    assert_response :success
    assert_includes response.body, "\"component\":\"diagnostics\""
  end

  test "http token auth protects token demo endpoint" do
    get "/action_pack/token_protected"
    assert_response :unauthorized

    credentials = ActionController::HttpAuthentication::Token.encode_credentials("demo-token")
    get "/action_pack/token_protected", headers: { "HTTP_AUTHORIZATION" => credentials }

    assert_response :success
  end

  test "authenticate_with_http_token supports optional non-challenge auth" do
    get "/action_pack/token_optional"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"authenticated\":false"
    assert_includes response.body, "\"token\":\"none\""

    credentials = ActionController::HttpAuthentication::Token.encode_credentials("demo-token")
    get "/action_pack/token_optional", headers: { "HTTP_AUTHORIZATION" => credentials }

    assert_response :success
    assert_includes response.body, "\"authenticated\":true"
    assert_includes response.body, "\"token\":\"demo-token\""
  end

  test "authenticate_with_http_basic and authenticate_with_http_digest support optional auth" do
    get "/action_pack/basic_optional"
    assert_response :success
    assert_includes response.body, "\"authenticated\":false"
    assert_includes response.body, "\"username\":\"none\""

    basic_credentials = ActionController::HttpAuthentication::Basic.encode_credentials("basic-user", "basic-secret")
    get "/action_pack/basic_optional", headers: { "HTTP_AUTHORIZATION" => basic_credentials }
    assert_response :success
    assert_includes response.body, "\"authenticated\":true"
    assert_includes response.body, "\"username\":\"basic-user\""

    get "/action_pack/digest_optional"
    assert_response :success
    assert_includes response.body, "\"authenticated\":false"

    get "/action_pack/digest_protected"
    assert_response :unauthorized

    challenge = response.headers["WWW-Authenticate"]
    digest_header = ActionController::HttpAuthentication::Digest.encode_credentials(
      "GET",
      {
        username: "digest-user",
        realm: challenge[/realm=\"([^\"]+)\"/, 1],
        nonce: challenge[/nonce=\"([^\"]+)\"/, 1],
        uri: "/action_pack/digest_optional",
        qop: "auth",
        nc: "00000001",
        cnonce: "123456abcdef",
        opaque: challenge[/opaque=\"([^\"]+)\"/, 1]
      },
      "digest-secret",
      false
    )

    get "/action_pack/digest_optional", headers: { "HTTP_AUTHORIZATION" => digest_header }
    assert_response :success
    assert_includes response.body, "\"authenticated\":true"
    assert_includes response.body, "\"username\":\"digest-user\""
  end

  test "http authentication direct helper endpoints emit challenges" do
    get "/action_pack/request_basic_auth"
    assert_response :unauthorized
    assert_match(/\ABasic /, response.headers["WWW-Authenticate"])

    get "/action_pack/request_token_auth"
    assert_response :unauthorized
    assert_match(/\AToken /, response.headers["WWW-Authenticate"])

    get "/action_pack/request_digest_auth"
    assert_response :unauthorized
    assert_match(/\ADigest /, response.headers["WWW-Authenticate"])
  end

  test "http digest auth protects digest demo endpoint" do
    get "/action_pack/digest_protected"
    assert_response :unauthorized

    challenge = response.headers["WWW-Authenticate"]
    digest_header = ActionController::HttpAuthentication::Digest.encode_credentials(
      "GET",
      {
        username: "digest-user",
        realm: challenge[/realm=\"([^\"]+)\"/, 1],
        nonce: challenge[/nonce=\"([^\"]+)\"/, 1],
        uri: "/action_pack/digest_protected",
        qop: "auth",
        nc: "00000001",
        cnonce: "abcdef123456",
        opaque: challenge[/opaque=\"([^\"]+)\"/, 1]
      },
      "digest-secret",
      false
    )

    get "/action_pack/digest_protected", headers: { "HTTP_AUTHORIZATION" => digest_header }

    assert_response :success
  end

  test "turbo helper panel renders explicit turbo frame and data helpers" do
    get "/action_pack/turbo_helper_panel"

    assert_response :success
    assert_includes response.body, "meta name=\"turbo-refresh-method\" content=\"morph\""
    assert_includes response.body, "meta name=\"turbo-refresh-scroll\" content=\"preserve\""
    assert_includes response.body, "<turbo-frame"
    assert_includes response.body, "id=\"demo_frame\""
    assert_includes response.body, "src=\"/docs/preview\""
    assert_includes response.body, "loading=\"lazy\""
    assert_includes response.body, "target=\"_top\""
    assert_includes response.body, "autoscroll"
    assert_includes response.body, "recurse=\"demo_child\""
    assert_includes response.body, "data-turbo-method=\"delete\""
    assert_includes response.body, "data-turbo-confirm=\"Are you sure?\""
    assert_includes response.body, "data-turbo-frame=\"demo_frame\""
  end

  test "turbo stream response can be negotiated explicitly" do
    get "/action_pack/turbo_stream_demo", headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, "<turbo-stream action=\"replace\" target=\"turbo_stream_target\">"
    assert_includes response.body, "turbo-stream-rendered"
  end

  test "turbo stream response supports morph rendering" do
    get "/action_pack/turbo_stream_demo", params: { mode: "morph" }, headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, "method=\"morph\""
    assert_includes response.body, "turbo-stream-morph-rendered"
  end

  test "turbo stream response supports refresh action" do
    get "/action_pack/turbo_stream_demo", params: { mode: "refresh" }, headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, "<turbo-stream"
    assert_includes response.body, "action=\"refresh\""
    assert_includes response.body, "request-id=\"demo-refresh\""
  end

  test "redirect_back_or_to uses referer when present and fallback otherwise" do
    get "/action_pack/fallback_redirect", headers: { "HTTP_REFERER" => docs_about_url }
    assert_redirected_to docs_about_url

    get "/action_pack/fallback_redirect"
    assert_redirected_to docs_preview_url
  end

  test "redirect_back uses referer when present and fallback otherwise" do
    get "/action_pack/redirect_back_demo", headers: { "HTTP_REFERER" => docs_about_url }
    assert_redirected_to docs_about_url

    get "/action_pack/redirect_back_demo"
    assert_redirected_to docs_preview_url
  end

  test "http_basic_authenticate_with protects only configured actions" do
    get "/action_pack/macro_auth_protected"
    assert_response :unauthorized
    assert_match(/\ABasic /, response.headers["WWW-Authenticate"])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("macro-user", "macro-secret")
    get "/action_pack/macro_auth_protected", headers: { "HTTP_AUTHORIZATION" => credentials }
    assert_response :success
    assert_equal "macro-protected", response.body

    get "/action_pack/macro_auth_open"
    assert_response :success
    assert_equal "macro-open", response.body
  end

  test "http_basic_authenticate_with can be scoped with except" do
    get "/action_pack/macro_auth_except_protected"
    assert_response :unauthorized
    assert_match(/\ABasic /, response.headers["WWW-Authenticate"])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("macro-except-user", "macro-except-secret")
    get "/action_pack/macro_auth_except_protected", headers: { "HTTP_AUTHORIZATION" => credentials }
    assert_response :success
    assert_equal "macro-except-protected", response.body

    get "/action_pack/macro_auth_except_open"
    assert_response :success
    assert_equal "macro-except-open", response.body
  end

  test "http_basic_authenticate_with supports realm" do
    get "/action_pack/macro_auth_realm_protected"
    assert_response :unauthorized
    assert_match(/realm=\"TeamHub Realm\"/, response.headers["WWW-Authenticate"])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("macro-realm-user", "macro-realm-secret")
    get "/action_pack/macro_auth_realm_protected", headers: { "HTTP_AUTHORIZATION" => credentials }
    assert_response :success
    assert_equal "macro-realm-protected", response.body
  end

  test "redirect_to supports proc and allow_other_host" do
    get "/action_pack/proc_redirect"
    assert_redirected_to docs_feed_url

    get "/action_pack/external_redirect"
    assert_equal "https://example.test/outbound", response.redirect_url

    get "/action_pack/status_redirect"
    assert_response :moved_permanently
    assert_redirected_to docs_preview_url
  end

  test "cache control helpers set cache headers" do
    get "/action_pack/cache_public"
    assert_response :success
    assert_includes response.headers["Cache-Control"], "max-age=300"
    assert_includes response.headers["Cache-Control"], "public"

    get "/action_pack/cache_now"
    assert_response :success
    assert_includes response.headers["Cache-Control"], "no-cache"
  end

  test "flash persists across redirect and flash.now is render-scoped" do
    get "/action_pack/flash_redirect"
    assert_redirected_to action_pack_flash_landing_url

    follow_redirect!
    assert_response :success
    assert_equal "flash-persisted", response.body

    get "/action_pack/flash_landing"
    assert_response :success
    assert_equal "no-flash", response.body

    get "/action_pack/flash_now_demo"
    assert_response :success
    assert_equal "flash-now", response.body

    get "/action_pack/flash_landing"
    assert_response :success
    assert_equal "no-flash", response.body
  end

  test "flash.keep preserves flash across multiple redirects" do
    get "/action_pack/flash_keep_start"
    assert_redirected_to action_pack_flash_keep_middle_url

    follow_redirect!
    assert_redirected_to action_pack_flash_keep_finish_url

    follow_redirect!
    assert_response :success
    assert_equal "flash-kept", response.body

    get "/action_pack/flash_keep_finish"
    assert_response :success
    assert_equal "no-flash", response.body
  end

  test "request variants select variant template when assigned" do
    get "/action_pack/variant_showcase"
    assert_response :success
    assert_equal "default-variant", response.body.strip

    get "/action_pack/variant_showcase", params: { mode: "phone" }
    assert_response :success
    assert_equal "phone-variant", response.body.strip
  end


  test "HEAD requests reuse GET response metadata without response body" do
    get "/action_pack/head_ready"
    assert_response :success
    assert_equal "ready", response.headers["X-Action-Pack-Head"]
    assert_equal "text/plain", response.media_type
    assert_equal "head-capable-body", response.body

    head "/action_pack/head_ready"
    assert_response :success
    assert_equal "ready", response.headers["X-Action-Pack-Head"]
    assert_equal "text/plain", response.media_type
    assert_equal "", response.body
  end


  test "turbo frame aware endpoint detects Turbo-Frame requests" do
    get "/action_pack/frame_aware"
    assert_response :success
    assert_includes response.body, "\"turbo_frame_request\":false"
    assert_includes response.body, "\"turbo_frame_request_id\":\"none\""

    get "/action_pack/frame_aware", headers: { "Turbo-Frame" => "sidebar" }
    assert_response :success
    assert_includes response.body, "\"turbo_frame_request\":true"
    assert_includes response.body, "\"turbo_frame_request_id\":\"sidebar\""
  end

  test "render_to_string endpoint renders partial html" do
    get "/action_pack/rendered_snippet"

    assert_response :success
    assert_includes response.body, "Action Pack"
    assert_includes response.body, "render_to_string"
  end

  test "respond_to advanced branches cover html json xml and format.any" do
    get "/action_pack/negotiated_resource"
    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "negotiated-html"

    get "/action_pack/negotiated_resource.json"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"format\":\"json\""

    get "/action_pack/negotiated_resource.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<source>action-pack-demo</source>"

    get "/action_pack/negotiated_resource.txt"
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_equal "negotiated-any", response.body
  end

  test "respond_to format.all falls back and head can set custom headers" do
    get "/action_pack/negotiated_fallback.txt"
    assert_response :not_acceptable
    assert_equal "format-all", response.headers["X-Action-Pack"]

    get "/action_pack/negotiated_fallback.json"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"format\":\"json-only\""
  end

  test "render can override content_type explicitly" do
    get "/action_pack/typed_render"

    assert_response :success
    assert_equal "text/markdown", response.media_type
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_equal "utf-8", response.charset
    assert_equal "typed-render", response.body
  end

  test "render partial supports explicit formats option" do
    get "/action_pack/partial_with_formats"

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "Partial Render"
    assert_includes response.body, "formats option"
  end

  test "render html supports layout false and status" do
    get "/action_pack/html_without_layout"

    assert_response :accepted
    assert_equal "text/html", response.media_type
    assert_equal "<div>html-no-layout</div>", response.body
    refute_includes response.body, "<!DOCTYPE html>"
  end

  test "controller helpers and view_context are available" do
    get "/action_pack/view_bridge"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"helpers_badge\":\"<span class=\\\"action-pack-badge\\\">bridge</span>\""
    assert_includes response.body, "\"view_context_is_action_view_base\":true"
  end

  test "request mutation setters are available" do
    get "/action_pack/request_mutation"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"remote_ip\":\"203.0.113.5\""
    assert_includes response.body, "\"request_parameters\":{\"manual\":\"set\",\"source\":\"action-pack-demo\"}"
  end

  test "request_parameters_list returns parsed key value pairs" do
    post "/action_pack/request_parameter_list", params: { alpha: "1", beta: "2" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"request_parameters_list\":[[\"alpha\",\"1\"],[\"beta\",\"2\"]]"
  end

  test "request_parameters alias reads parsed post parameters" do
    post "/action_pack/request_parameters_alias", params: { gamma: "3", delta: "4" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"request_parameters\":{\"gamma\":\"3\",\"delta\":\"4\"}"
  end

  test "controller response writers can set status and content type" do
    get "/action_pack/response_writers"

    assert_response :accepted
    assert_equal "text/plain", response.media_type
    assert_equal "writer-body", response.body
  end

  test "controller location writer can set location header" do
    get "/action_pack/location_writer"

    assert_response :created
    assert_equal "text/plain", response.media_type
    assert_equal docs_about_url, response.headers["Location"]
    assert_equal "location-writer-body", response.body
  end

  test "controller response readers expose delegated response values" do
    get "/action_pack/response_readers"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "\"status\":202"
    assert_includes response.body, "\"location\":\"#{docs_about_url}\""
    assert_includes response.body, "\"content_type\":\"text/plain; charset=utf-8\""
    assert_includes response.body, "\"media_type\":\"text/plain\""
  end

  test "controller headers proxy can write response headers" do
    get "/action_pack/header_proxy"

    assert_response :success
    assert_equal "controller-headers", response.headers["X-Action-Pack-Proxy"]
    assert_equal "transient", response.headers["X-Action-Pack-Deleted"]
    assert_nil response.headers["X-Action-Pack-Temp"]
    assert_equal "header-proxy-body", response.body
  end

  test "request body_stream exposes raw request body" do
    post "/action_pack/body_stream_demo",
      params: "{\"stream\":\"value\"}",
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"body_stream\":\"{\\\"stream\\\":\\\"value\\\"}\""
  end

  test "performed state and response_body assignment are available" do
    get "/action_pack/execution_state"

    assert_response :success
    assert_equal "manual-body", response.body
    assert_equal "false", response.headers["X-Performed-Before"]
    assert_equal "true", response.headers["X-Performed-After"]
    assert_equal "[\"manual-body\"]", response.headers["X-Response-Body"]
    assert_equal "[\"manual-body\"]", response.headers["X-Response-Body-Reader"]
  end

  test "render_to_body and view_assigns are available" do
    get "/action_pack/rendering_bridge"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"body\":\"<section class=\\\"action-pack-summary\\\">"
    assert_includes response.body, "Render To Body"
    assert_includes response.body, "\"view_assigns\":{\"bridge_note\":\"assigned-through-controller\"}"
  end

  test "render json can set created status and location header" do
    get "/action_pack/json_created"

    assert_response :created
    assert_equal docs_about_url, response.headers["Location"]
    assert_includes response.body, "\"resource\":\"action-pack-demo\""
  end

  test "request and response accessors are available" do
    post "/action_pack/request_response_details/42",
      params: { visible: "yes", token: "secret-token" },
      headers: { "HTTP_AUTHORIZATION" => "Token token=\"demo-token\"" },
      as: :json

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal docs_about_url, response.headers["Location"]
    assert_match(/\"request_id\":\"[^\"]+\"/, response.body)
    assert_includes response.body, "\"id\":\"42\""
    assert_includes response.body, "\"raw_post\":\"{\\\"visible\\\":\\\"yes\\\",\\\"token\\\":\\\"secret-token\\\"}\""
    assert_includes response.body, "\"body_string\":\"{\\\"visible\\\":\\\"yes\\\",\\\"token\\\":\\\"secret-token\\\"}\""
    assert_includes response.body, "\"form_data\":false"
    assert_includes response.body, "\"server_software\":null"
    assert_includes response.body, "\"visible\":\"yes\""
    assert_includes response.body, "\"token\":\"[FILTERED]\""
    assert_includes response.body, "\"authorization\":\"Token token=\\\"demo-token\\\"\""
    assert_includes response.body, "\"method_symbol\":\"post\""
    assert_includes response.body, "\"media_type\":\"application/json\""
    assert_includes response.body, "\"ip\":\"127.0.0.1\""
    assert_includes response.body, "\"response_media_type\":\"application/json\""
    assert_includes response.body, "\"response_status\":200"
    assert_includes response.body, "\"response_code\":\"200\""
    assert_includes response.body, "\"response_message\":\"OK\""
    assert_includes response.body, "\"response_status_message\":\"OK\""
    assert_includes response.body, "\"response_content_length\":"
    assert_includes response.body, "\"response_headers\":{\"content_type\":\"application/json; charset=utf-8\",\"location\":\"#{docs_about_url}\"}"
    assert_includes response.body, "\"response_header_checks\":{\"has_location\":true,\"location\":\"#{docs_about_url}\"}"
    assert_includes response.body, "\"response_header_mutation\":{\"before_delete\":\"temp\",\"after_delete\":null}"
  end

  test "request predicate and format variants are available" do
    get "/action_pack/request_variants",
      headers: {
        "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
        "HTTP_REFERER" => docs_preview_url,
        "HTTP_USER_AGENT" => "TeamHubActionPackTest/1.0",
        "HTTP_X_CUSTOM_HEADER" => "demo-value"
      }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"xhr\":true"
    assert_includes response.body, "\"xml_http_request\":true"
    assert_includes response.body, "\"format\":\"text/html\""
    assert_includes response.body, "\"get\":true"
    assert_includes response.body, "\"post\":false"
    assert_includes response.body, "\"put\":false"
    assert_includes response.body, "\"patch\":false"
    assert_includes response.body, "\"delete\":false"
    assert_includes response.body, "\"head\":false"
    assert_includes response.body, "\"method\":\"GET\""
    assert_includes response.body, "\"request_method\":\"GET\""
    assert_includes response.body, "\"logger_present\":true"
    assert_includes response.body, "\"logger_matches_rails\":true"
    assert_includes response.body, "\"content_length\":0"
    assert_includes response.body, "\"host\":\"www.example.com\""
    assert_includes response.body, "\"host_with_port\":\"www.example.com\""
    assert_includes response.body, "\"base_url\":\"http://www.example.com\""
    assert_includes response.body, "\"protocol\":\"http://\""
    assert_includes response.body, "\"port\":80"
    assert_includes response.body, "\"ssl\":false"
    assert_includes response.body, "\"local\":true"
    assert_includes response.body, "\"domain\":\"example.com\""
    assert_includes response.body, "\"subdomain\":\"www\""
    assert_includes response.body, "\"subdomains\":[\"www\"]"
    assert_includes response.body, "\"referer\":\"#{docs_preview_url}\""
    assert_includes response.body, "\"user_agent\":\"TeamHubActionPackTest/1.0\""
    assert_includes response.body, "\"custom_header\":\"demo-value\""
    assert_includes response.body, "\"path\":\"/action_pack/request_variants\""
    assert_includes response.body, "\"path_info\":\"/action_pack/request_variants\""
    assert_includes response.body, "\"script_name\":\"\""
    assert_includes response.body, "\"url\":\"http://www.example.com/action_pack/request_variants\""
    assert_includes response.body, "\"original_url\":\"http://www.example.com/action_pack/request_variants\""
    assert_includes response.body, "\"fullpath\":\"/action_pack/request_variants\""
    assert_includes response.body, "\"query_string\":\"\""
    assert_includes response.body, "\"inspect\":\"#<ActionDispatch::Request GET"
    assert_includes response.body, "for 127.0.0.1>\""

    post "/action_pack/request_variants?view=compact", as: :json
    assert_response :success
    assert_includes response.body, "\"xhr\":false"
    assert_includes response.body, "\"xml_http_request\":false"
    assert_includes response.body, "\"format\":\"application/json\""
    assert_includes response.body, "\"get\":false"
    assert_includes response.body, "\"post\":true"
    assert_includes response.body, "\"put\":false"
    assert_includes response.body, "\"patch\":false"
    assert_includes response.body, "\"delete\":false"
    assert_includes response.body, "\"head\":false"
    assert_includes response.body, "\"method\":\"POST\""
    assert_includes response.body, "\"host_with_port\":\"www.example.com\""
    assert_includes response.body, "\"base_url\":\"http://www.example.com\""
    assert_includes response.body, "\"referer\":\"none\""
    assert_includes response.body, "\"user_agent\":\"none\""
    assert_includes response.body, "\"custom_header\":\"none\""
    assert_includes response.body, "\"path_info\":\"/action_pack/request_variants\""
    assert_includes response.body, "\"script_name\":\"\""
    assert_includes response.body, "\"request_method\":\"POST\""
    assert_includes response.body, "\"logger_present\":true"
    assert_includes response.body, "\"logger_matches_rails\":true"
    assert_includes response.body, "\"content_length\":0"
    assert_includes response.body, "\"port\":80"
    assert_includes response.body, "\"ssl\":false"
    assert_includes response.body, "\"local\":true"
    assert_includes response.body, "\"domain\":\"example.com\""
    assert_includes response.body, "\"subdomain\":\"www\""
    assert_includes response.body, "\"subdomains\":[\"www\"]"
    assert_includes response.body, "\"path\":\"/action_pack/request_variants\""
    assert_includes response.body, "\"url\":\"http://www.example.com/action_pack/request_variants?view=compact\""
    assert_includes response.body, "\"original_url\":\"http://www.example.com/action_pack/request_variants?view=compact\""
    assert_includes response.body, "\"fullpath\":\"/action_pack/request_variants?view=compact\""
    assert_includes response.body, "\"query_string\":\"view=compact\""
    assert_includes response.body, "\"inspect\":\"#<ActionDispatch::Request POST"
    assert_includes response.body, "for 127.0.0.1>\""

    put "/action_pack/request_variants", params: { updated: "true" }, as: :json
    assert_response :success
    assert_includes response.body, "\"put\":true"
    assert_includes response.body, "\"patch\":false"
    assert_includes response.body, "\"delete\":false"
    assert_includes response.body, "\"head\":false"
    assert_includes response.body, "\"method\":\"PUT\""

    patch "/action_pack/request_variants", params: { patched: "yes" }, as: :json
    assert_response :success
    assert_includes response.body, "\"put\":false"
    assert_includes response.body, "\"patch\":true"
    assert_includes response.body, "\"delete\":false"
    assert_includes response.body, "\"head\":false"
    assert_includes response.body, "\"method\":\"PATCH\""

    delete "/action_pack/request_variants", params: { removed: "1" }, as: :json
    assert_response :success
    assert_includes response.body, "\"put\":false"
    assert_includes response.body, "\"patch\":false"
    assert_includes response.body, "\"delete\":true"
    assert_includes response.body, "\"head\":false"
    assert_includes response.body, "\"method\":\"DELETE\""
  end

  test "additional renderers respond" do
    get "/action_pack/inline_render"
    assert_response :success
    assert_includes response.body, "inline-rendered 2"

    get "/action_pack/body_render"
    assert_response :success
    assert_equal "body-rendered", response.body

    get "/action_pack/plain_without_layout"
    assert_response :success
    assert_equal "plain-no-layout", response.body

    get "/action_pack/file_render"
    assert_response :success
    assert_includes response.body, "file-rendered"

    get "/action_pack/renderer_demo"
    assert_response :success
    assert_includes response.body, "Renderer"
    assert_includes response.body, "class renderer"

    get "/action_pack/template_render_demo"
    assert_response :success
    assert_includes response.body, "id=\"action-pack-template-render\">template-rendered-explicitly<"

    get "/action_pack/collection_render_demo"
    assert_response :success
    assert_includes response.body, "class=\"action-pack-collection-layout\""
    assert_includes response.body, "class=\"action-pack-collection-item\">alpha<"
    assert_includes response.body, "class=\"action-pack-collection-item\">beta<"
  end

  test "helper dsl helper_method methods and default_url_options render helper panel" do
    get "/action_pack/helper_panel", params: { query: "demo", status: "active", stage: "doing", locale: "ja" }

    assert_response :success
    assert_includes response.body, "action-pack-badge"
    assert_includes response.body, "class=\"project\""
    assert_includes response.body, "id=\"action-pack-captured\">"
    assert_includes response.body, "captured-helper"
    assert_includes response.body, "id=\"action-pack-concat\""
    assert_includes response.body, "id=\"action-pack-safe-join\""
    assert_includes response.body, "safe"
    assert_includes response.body, "join"
    assert_includes response.body, "id=\"action_pack_query\""
    assert_includes response.body, "value=\"demo\""
    assert_includes response.body, "<option selected=\"selected\" value=\"active\">Active</option>"
    assert_includes response.body, "<optgroup label=\"Open\">"
    assert_includes response.body, "<option selected=\"selected\" value=\"doing\">Doing</option>"
    assert_includes response.body, "id=\"action_pack_button_tag\""
    assert_includes response.body, "name=\"filters[project_id]\""
    assert_includes response.body, "name=\"commit\""
    assert_includes response.body, "id=\"action-pack-time-ago\">"
    assert_includes response.body, "id=\"action-pack-current-page\">true<"
    assert_includes response.body, "id=\"action-pack-current-user\">#{users(:one).email}<"
    assert_includes response.body, "id=\"action-pack-signed-in\">true<"
    assert_includes response.body, "id=\"action-pack-inline-helper\">inline-helper<"
    assert_includes response.body, "id=\"action-pack-default-url-path\">/docs/preview?locale=ja<"
    assert_includes response.body, "id=\"action-pack-default-url-url\">http://www.example.com/docs/preview?locale=ja<"
    assert_includes response.body, "id=\"action-pack-simple-format\">"
    assert_includes response.body, "Alpha</p>"
    assert_includes response.body, "id=\"action-pack-truncate\">abcde..."
    assert_includes response.body, "id=\"action-pack-excerpt\">"
    assert_includes response.body, "id=\"action-pack-highlight\">"
    assert_includes response.body, "<mark>helper</mark>"
    assert_includes response.body, "id=\"action-pack-cycle\">odd<"
    assert_includes response.body, "id=\"action-pack-number-currency\">$12.34<"
    assert_includes response.body, "id=\"action-pack-number-percentage\">12.3%<"
    assert_includes response.body, "id=\"action-pack-number-phone\">555-123-4567<"
    assert_includes response.body, "id=\"action-pack-number-rounded\">12.35<"
    assert_includes response.body, "id=\"action-pack-number-human\">12.3 Thousand<"
    assert_includes response.body, "id=\"action-pack-mail-to\">"
    assert_includes response.body, "mailto:support@example.test"
    assert_includes response.body, "id=\"action-pack-phone-to\">"
    assert_includes response.body, "tel:5551234567"
    assert_includes response.body, "id=\"action-pack-picture-tag\">"
    assert_includes response.body, "<picture"
    assert_includes response.body, "id=\"action-pack-video-tag\">"
    assert_includes response.body, "<video"
    assert_includes response.body, "id=\"action-pack-audio-tag\">"
    assert_includes response.body, "<audio"
    assert_includes response.body, "id=\"action-pack-favicon-tag\">"
    assert_includes response.body, "rel=\"icon\""
    assert_includes response.body, "id=\"action-pack-feed-tag\">"
    assert_includes response.body, "rel=\"alternate\""
    assert_includes response.body, "type=\"application/atom+xml\""
    assert_includes response.body, "id=\"action-pack-javascript-include-tag\">"
    assert_includes response.body, "<script"
  end

  test "filter DSL controller runs prepend and append filters" do
    get "/action_pack/filter_dsl"

    assert_response :success
    assert_includes response.body, "prepend_around_before"
    assert_includes response.body, "append_around_before"
    assert_includes response.body, "prepend_before"
    assert_includes response.body, "before"
    assert_includes response.body, "append_before"
    assert_includes response.body, "action"
    assert_includes response.headers["X-Filter-Order"], "append_after"
    assert_includes response.headers["X-Filter-Order"], "append_around_after"
    assert_includes response.headers["X-Filter-Order"], "around_after"

    source = File.read(Rails.root.join("app/controllers/demo/filter_dsl_demos_controller.rb"))
    assert_includes source, "prepend_after_action"
    assert_includes source, "after_action"
    assert_includes source, "append_after_action"
    assert_includes source, "prepend_around_action"
    assert_includes source, "around_action"
    assert_includes source, "append_around_action"
  end

  test "view path mutation can prepend and append lookup paths" do
    get "/action_pack/view_path_prepend"
    assert_response :success
    assert_includes response.body, "prepended-view-path"

    get "/action_pack/view_path_append"
    assert_response :success
    assert_includes response.body, "appended-view-path"
  end

  test "controller level csrf DSL controllers are wired" do
    get "/action_pack/csrf_dsl_protected"
    assert_response :success
    assert_equal "csrf-protected", response.body

    get "/action_pack/csrf_skip"
    assert_response :success
    assert_equal "csrf-skipped", response.body

    protected_source = File.read(Rails.root.join("app/controllers/demo/csrf_dsl_demos_controller.rb"))
    skipped_source = File.read(Rails.root.join("app/controllers/demo/csrf_skip_demos_controller.rb"))

    assert_includes protected_source, "protect_from_forgery"
    assert_includes skipped_source, "skip_forgery_protection"
  end

  test "wrap parameters wraps JSON payload into configured key" do
    post "/action_pack/wrap_parameters", params: { title: "wrapped-demo" }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"title\":\"wrapped-demo\""
    assert_includes response.body, "\"payload\":"
  end

  test "signed encrypted and permanent cookie jars can be written and read" do
    get "/cookies/write_demo"
    assert_response :success
    set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
    assert_includes set_cookie, "teamhub_signed_expires"
    assert_includes set_cookie, "teamhub_encrypted_expires"
    assert_includes set_cookie.downcase, "expires="

    get "/cookies/read_demo"
    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal "GET", response.headers["X-TeamHub-Request-Method"]
    assert_includes response.body, "\"signed\":\"signed-value\""
    assert_includes response.body, "\"encrypted\":\"encrypted-value\""
    assert_includes response.body, "\"signed_expires\":\"signed-expires-value\""
    assert_includes response.body, "\"encrypted_expires\":\"encrypted-expires-value\""
    assert_includes response.body, "\"permanent\":\"permanent-value\""
    assert_includes response.body, "\"signed_permanent\":\"signed-permanent-value\""
    assert_includes response.body, "\"encrypted_permanent\":\"encrypted-permanent-value\""

    get "/cookies/clear_demo"
    assert_response :success

    get "/cookies/read_demo"
    assert_response :success
    assert_includes response.body, "\"signed\":null"
    assert_includes response.body, "\"encrypted\":null"
    assert_includes response.body, "\"signed_expires\":null"
    assert_includes response.body, "\"encrypted_expires\":null"
    assert_includes response.body, "\"permanent\":null"
    assert_includes response.body, "\"signed_permanent\":null"
    assert_includes response.body, "\"encrypted_permanent\":null"
  end

  test "controller can override default_url_options for a specific action" do
    get "/action_pack/scoped_url_defaults_demo"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "\"path\":\"/docs/preview?section=action_pack\""
    assert_includes response.body, "\"url\":\"http://www.example.com/docs/preview?section=action_pack\""
  end

  test "allow_browser blocks legacy browsers" do
    get root_url, headers: { "HTTP_USER_AGENT" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" }

    assert_response :not_acceptable
  end

  test "allow_browser can be scoped with only" do
    legacy_headers = { "HTTP_USER_AGENT" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" }

    get "/action_pack/browser_scope_restricted", headers: legacy_headers
    assert_response :not_acceptable

    get "/action_pack/browser_scope_open", headers: legacy_headers
    assert_response :success
    assert_equal "browser-scope-open", response.body
  end

  test "allow_browser can be scoped with except" do
    legacy_headers = { "HTTP_USER_AGENT" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" }

    get "/action_pack/browser_except_restricted", headers: legacy_headers
    assert_response :not_acceptable

    get "/action_pack/browser_except_open", headers: legacy_headers
    assert_response :success
    assert_equal "browser-except-open", response.body
  end

  test "redirect_to supports notice and alert shortcuts" do
    get "/action_pack/redirect_notice_shortcut"
    assert_redirected_to action_pack_flash_landing_url
    follow_redirect!
    assert_equal "notice-shortcut", response.body

    get "/action_pack/redirect_alert_shortcut"
    assert_redirected_to action_pack_flash_alert_landing_url
    follow_redirect!
    assert_equal "alert-shortcut", response.body
  end

  test "redirect_to supports status with notice and alert shortcuts" do
    get "/action_pack/redirect_notice_status_shortcut"
    assert_response :see_other
    assert_redirected_to action_pack_flash_landing_url
    follow_redirect!
    assert_equal "notice-status-shortcut", response.body

    get "/action_pack/redirect_alert_status_shortcut"
    assert_response :temporary_redirect
    assert_redirected_to action_pack_flash_alert_landing_url
    follow_redirect!
    assert_equal "alert-status-shortcut", response.body
  end

  test "rescue_from handles multiple exception types with distinct responses" do
    get "/error_demos/argument"
    assert_response :bad_request
    assert_includes response.body, "\"type\":\"ArgumentError\""

    get "/error_demos/key"
    assert_response :unprocessable_entity
    assert_includes response.body, "\"type\":\"KeyError\""
  end

  test "turbo native navigation helpers redirect to native historical locations" do
    headers = { "User-Agent" => "Hotwire Native iOS" }

    get "/native_demos/recede", headers: headers
    assert_match %r{/recede_historical_location}, response.redirect_url

    get "/native_demos/resume", headers: headers
    assert_match %r{/resume_historical_location}, response.redirect_url

    get "/native_demos/refresh", headers: headers
    assert_match %r{/refresh_historical_location}, response.redirect_url
  end

  test "turbo native navigation helpers fall back to normal web redirects" do
    get "/native_demos/recede"
    assert_redirected_to root_url
  end

  test "dashboard renders extra content_for blocks and form_with variants" do
    get dashboard_url
    assert_response :success
    assert_includes response.body, "name=\"teamhub-dashboard\""
    assert_includes response.body, "name=\"teamhub-dashboard-extra\""
    assert_includes response.body, "action=\"/dashboard\""
    assert_includes response.body, "action=\"/docs/preview\""
    assert_includes response.body, "signed-stream-name="
  end
end
