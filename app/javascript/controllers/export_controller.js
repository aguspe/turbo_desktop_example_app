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
    if (!td) return alert("Export needs the desktop app.")

    const picked = await td.sendBridgeMessage("file-picker", "save", {
      title: "Export tasks as CSV",
    })
    if (!picked || picked.status !== "selected") return

    const csv = await (await fetch("/tasks.csv")).text()
    const written = await td.fs.write(picked.path, csv)

    if (written && written.status === "ok") {
      td.sendBridgeMessage("notification", "show", {
        title: "Tasks exported",
        body: picked.path,
      })
    }
  }
}
