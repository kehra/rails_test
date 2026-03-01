// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "controllers"
import "trix"
import "@rails/actiontext"
import "channels"

Turbo.session.drive = true
Turbo.setProgressBarDelay(75)
Turbo.config.forms.mode = "optin"
Turbo.StreamActions.highlight = function() {
  this.targetElements.forEach((element) => element.classList.add("turbo-highlight"))
}

window.Turbo = Turbo
window.TeamhubTurboDemo = {
  clearCache() {
    Turbo.cache.clear()
  },

  connectTemporarySource() {
    const source = new EventTarget()
    Turbo.connectStreamSource(source)
    Turbo.disconnectStreamSource(source)
    return source
  },

  renderHighlight(target = "notifications") {
    Turbo.renderStreamMessage(
      `<turbo-stream action="highlight" target="${target}"><template></template></turbo-stream>`
    )
  },

  visitDocs() {
    Turbo.visit("/docs/preview")
  }
}

document.addEventListener("turbo:before-fetch-request", () => {
  document.documentElement.dataset.turboBeforeFetchRequest = "true"
})

document.addEventListener("turbo:before-fetch-response", () => {
  document.documentElement.dataset.turboBeforeFetchResponse = "true"
})

document.addEventListener("turbo:submit-end", () => {
  document.documentElement.dataset.turboSubmitEnd = "true"
})

ActiveStorage.start()
