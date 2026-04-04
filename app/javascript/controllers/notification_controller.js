// Notification Bridge Component
//
// This Stimulus controller demonstrates how to use Turbo Desktop's bridge
// to trigger native OS notifications from your Rails views.
//
// In the HTML, attach it like this:
//
//   <button data-controller="notification"
//           data-notification-title-value="Task Done!"
//           data-notification-body-value="Your task was completed.">
//     Complete
//   </button>
//
// When the button is clicked, it sends a bridge message to the Turbo Desktop
// shell, which shows a native macOS/Windows/Linux notification.
//
// If the app is running in a regular browser (not Turbo Desktop), the bridge
// call is a no-op — it won't throw errors, it just does nothing.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: { type: String, default: "Notification" },
    body:  { type: String, default: "" }
  }

  notify() {
    // TurboDesktop is injected by the desktop shell's turbo-desktop.js
    // It's only available when running inside the native app
    if (typeof TurboDesktop !== "undefined") {
      TurboDesktop.sendBridgeMessage("notification", "connect", {
        title: this.titleValue,
        body: this.bodyValue
      })
    }
  }
}
