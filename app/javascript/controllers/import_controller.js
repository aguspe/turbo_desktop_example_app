// CSV import from the desktop, two ways in:
//
// 1. Drag a .csv from the Finder/Explorer onto the window — the shell hands
//    the page real paths as a `turbo-desktop:drop` DOM event, already granted
//    for reading.
// 2. Open a .csv with the app (double-click, "Open With…", drop on the dock
//    icon) — arrives as `turbo-desktop:file-open`, even when that launch
//    started the app.
//
//   <div data-controller="import"
//        data-action="turbo-desktop:drop@document->import#filesDropped
//                     turbo-desktop:file-open@document->import#filesDropped
//                     turbo-desktop:drag-enter@document->import#highlight
//                     turbo-desktop:drag-leave@document->import#unhighlight">
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async filesDropped(event) {
    this.unhighlight()
    const td = window.TurboDesktop
    if (!td) return

    const paths = (event.detail.paths || []).filter((p) => p.endsWith(".csv"))
    for (const path of paths) {
      const file = await td.fs.read(path)
      if (!file || file.status !== "ok") continue

      const token = document.querySelector('meta[name="csrf-token"]')?.content
      await fetch("/tasks/import", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
        body: JSON.stringify({ csv: file.content }),
      })
    }

    if (paths.length > 0 && window.Turbo) window.Turbo.visit("/tasks")
  }

  highlight() {
    this.element.classList.add("drop-target")
  }

  unhighlight() {
    this.element.classList.remove("drop-target")
  }
}
