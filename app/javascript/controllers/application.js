import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
application.registerActionOption("open", ({ value, event }) => {
  return !value || event.type === "click" || event.type === "hello:ready"
})

window.Stimulus   = application

export { application }
