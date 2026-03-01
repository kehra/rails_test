import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { state: String }

  connect() {
    this.element.dataset.statusState = this.stateValue || "idle"
  }
}
