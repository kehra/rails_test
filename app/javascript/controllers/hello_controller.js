import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { name: String }
  static classes = ["state"]
  static outlets = ["status"]

  static shouldLoad() {
    return true
  }

  static afterLoad(identifier, application) {
    window.__teamhubStimulusAfterLoad = { identifier, debug: application.debug }
  }

  initialize() {
    this.element.dataset.helloIdentifier = this.identifier
    this.element.dataset.helloDebug = String(this.application.debug)
  }

  connect() {
    if (this.targets.has("output")) {
      this.outputTarget.textContent = this.greetingText()
    }

    if (this.classes.has("state")) {
      this.element.classList.add(this.stateClass)
    }

    this.element.dataset.helloHasStatusOutlet = String(this.outlets.has("status"))
    this.element.dataset.helloStatusOutletCount = String(this.outlets.findAll("status").length)

    this.dispatch("ready", { detail: { greeting: this.greetingText() } })
  }

  disconnect() {
    this.element.dataset.helloDisconnected = "true"
  }

  greet(event) {
    if (this.targets.has("output")) {
      const suffix = event?.params?.suffix
      this.outputTarget.textContent = suffix ? `${this.greetingText()} (${suffix})` : `${this.greetingText()} (greeted)`
    }
  }

  sync(event) {
    this.element.dataset.helloSyncedFrom = event?.type || "unknown"
  }

  nameValueChanged() {
    if (this.targets.has("output")) {
      this.outputTarget.textContent = this.greetingText()
    }
  }

  outputTargetConnected(element) {
    element.dataset.connected = "true"
  }

  outputTargetDisconnected(element) {
    element.dataset.disconnected = "true"
  }

  statusOutletConnected(outlet, element) {
    this.element.dataset.helloOutletState = `${outlet.stateValue}:${element.dataset.statusState || "pending"}`
  }

  statusOutletDisconnected() {
    this.element.dataset.helloOutletDisconnected = "true"
  }

  greetingText() {
    return `Hello ${this.nameValue}!`
  }
}
