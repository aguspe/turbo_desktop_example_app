// The part of the origin badge only the shell can answer: which window this
// is, how big, and whether the app was built for release.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["window", "build"]

  async connect() {
    const shell = window.TurboDesktop
    if (!shell || !this.hasWindowTarget) return

    const info = await shell.getWindowInfo()
    if (!info) {
      this.windowTarget.textContent = "The shell did not answer"
      this.buildTarget.textContent = "Unknown"
      return
    }

    const scale = info.scaleFactor || 1
    const size = `${Math.round(info.width / scale)}×${Math.round(info.height / scale)}`
    this.windowTarget.textContent = `${info.label}${shell.isModal ? " (modal)" : ""}, ${size}`
    this.buildTarget.textContent = info.development === false ? "Release, from a bundle" : "Development"
  }
}
