// The system clipboard, past the webview's limits: write without a user
// gesture on the page, read what another application copied.
//
//   Copy:  <button data-controller="clipboard"
//                  data-clipboard-text-value="<%= task.title %>"
//                  data-action="clipboard#copy">Copy</button>
//   Paste: <button data-controller="clipboard"
//                  data-action="clipboard#pasteAsTask">New task from clipboard</button>
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    const td = window.TurboDesktop
    if (!td) return
    await td.clipboard.writeText(this.textValue)
    td.sendBridgeMessage("notification", "show", {
      title: "Copied to clipboard",
      body: this.textValue,
    })
  }

  async pasteAsTask() {
    const td = window.TurboDesktop
    if (!td) return

    const text = await td.clipboard.readText()
    if (!text) {
      return td.sendBridgeMessage("notification", "show", {
        title: "Clipboard is empty",
        body: "Copy some text anywhere, then try again.",
      })
    }

    const [title, ...rest] = text.split("\n")
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch("/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({
        task: { title: title.slice(0, 120), description: rest.join("\n") },
      }),
    })
    if (window.Turbo) window.Turbo.visit("/tasks")
  }
}
