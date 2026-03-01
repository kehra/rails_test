require "test_helper"

class HotwireJavascriptApiTest < ActiveSupport::TestCase
  test "application javascript configures turbo session and progress bar" do
    source = File.read(Rails.root.join("app/javascript/application.js"))

    assert_includes source, "Turbo.session.drive = true"
    assert_includes source, "Turbo.setProgressBarDelay(75)"
    assert_includes source, "Turbo.config.forms.mode = \"optin\""
    assert_includes source, "Turbo.cache.clear()"
    assert_includes source, "Turbo.connectStreamSource(source)"
    assert_includes source, "Turbo.disconnectStreamSource(source)"
    assert_includes source, "Turbo.renderStreamMessage("
    assert_includes source, "Turbo.visit(\"/docs/preview\")"
    assert_includes source, "Turbo.StreamActions.highlight"
    assert_includes source, "\"turbo:before-fetch-request\""
    assert_includes source, "\"turbo:before-fetch-response\""
    assert_includes source, "\"turbo:submit-end\""
  end

  test "hello controller uses advanced stimulus lifecycle and callback APIs" do
    source = File.read(Rails.root.join("app/javascript/controllers/hello_controller.js"))

    assert_includes source, "static shouldLoad()"
    assert_includes source, "static afterLoad(identifier, application)"
    assert_includes source, "static outlets = [\"status\"]"
    assert_includes source, "initialize()"
    assert_includes source, "disconnect()"
    assert_includes source, "nameValueChanged()"
    assert_includes source, "outputTargetConnected(element)"
    assert_includes source, "outputTargetDisconnected(element)"
    assert_includes source, "statusOutletConnected(outlet, element)"
    assert_includes source, "statusOutletDisconnected()"
    assert_includes source, "this.dispatch(\"ready\""
    assert_includes source, "this.identifier"
    assert_includes source, "this.application"
    assert_includes source, "this.targets.has(\"output\")"
    assert_includes source, "this.classes.has(\"state\")"
    assert_includes source, "this.outlets.has(\"status\")"
    assert_includes source, "this.outlets.findAll(\"status\")"
  end

  test "stimulus application registers a custom action option" do
    source = File.read(Rails.root.join("app/javascript/controllers/application.js"))

    assert_includes source, "application.registerActionOption(\"open\""
  end

  test "status controller exists for outlet wiring" do
    source = File.read(Rails.root.join("app/javascript/controllers/status_controller.js"))

    assert_includes source, "static values = { state: String }"
  end

  test "dashboard view wires advanced stimulus action descriptors" do
    source = File.read(Rails.root.join("app/views/dashboard/index.html.erb"))

    assert_includes source, "click->hello#greet:open:prevent"
    assert_includes source, "keydown.enter->hello#greet"
    assert_includes source, "resize@window->hello#sync"
    assert_includes source, "teamhub:refresh@document->hello#sync"
    assert_includes source, "hello:ready->hello#greet:open"
    assert_includes source, "data-hello-suffix-param=\"clicked\""
    assert_includes source, "data-hello-status-outlet=\".status-probe\""
    assert_includes source, "data-controller=\"status\""
  end
end
