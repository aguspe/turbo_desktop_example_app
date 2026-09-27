// CSV export through the native save dialog.
//
// Shows what a dialog pick means in Turbo Desktop: the config allows no
// filesystem roots at all, yet the write succeeds anywhere the user points
// the dialog — choosing a location is consent to write there.
//
//   <button data-controller="export" data-action="export#save">Export…</button>
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async save() {
    const td = window.TurboDesktop
    if (!td) return this.say("Export needs the desktop app.", "alert")

    const picked = await td.sendBridgeMessage("file-picker", "save", {
      title: "Export tasks as CSV",
      defaultName: "tasks.csv",
      filters: [{ name: "CSV", extensions: ["csv"] }],
    })
    if (!picked) return this.say("The save dialog could not be opened.", "alert")
    if (picked.status !== "selected") return

    const csv = await (await fetch("/tasks.csv")).text()
    const written = await td.fs.write(picked.path, csv)

    if (written && written.status === "ok") {
      const rows = csv.trim().split("\n").length - 1
      this.say(`${rows} tasks exported to ${picked.path}`, "notice")
      td.sendBridgeMessage("notification", "show", { title: "Tasks exported", body: picked.path })
    } else {
      this.say(`Could not write ${picked.path}.`, "alert")
    }
  }

  // Said in the page, where it will be seen: a notification can be silenced.
  say(message, kind) {
    document.querySelectorAll(".export-result").forEach((old) => old.remove())

    const flash = document.createElement("div")
    flash.className = `flash flash-${kind} export-result`
    flash.textContent = message
    document.querySelector("main").prepend(flash)
  }
}
