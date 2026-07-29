// Launch-at-login, driven by a visible toggle — never turned on silently.
//
//   <label data-controller="autostart">
//     <input type="checkbox" data-autostart-target="checkbox"
//            data-action="autostart#toggle">
//     Start Task Manager when I log in
//   </label>
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  async connect() {
    const td = window.TurboDesktop
    if (!td) return this.element.classList.add("hidden")
    this.checkboxTarget.checked = await td.autostart.isEnabled()
  }

  async toggle() {
    const td = window.TurboDesktop
    if (!td) return

    if (this.checkboxTarget.checked) {
      await td.autostart.enable()
    } else {
      await td.autostart.disable()
    }
  }
}
