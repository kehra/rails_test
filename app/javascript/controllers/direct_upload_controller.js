import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  start() {
    this.statusTarget.textContent = "Uploading..."
  }

  error(event) {
    event.preventDefault()
    this.statusTarget.textContent = `Upload failed: ${event.detail.error}`
  }

  end() {
    this.statusTarget.textContent = "Upload complete"
  }
}
