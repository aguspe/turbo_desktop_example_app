// Desktop checks: scenarios that involve the operating system, which no
// automated test can reach. Each card marks itself when the app sees the
// thing happen, and the outcome is kept so a run survives a restart, which
// several of the scenarios ask for.
//
// States: waiting → running → pass | fail | unavailable
import { Controller } from "@hotwired/stimulus"

const STORE = "td:checks"
const SIZE = "td:checks:size"
const LABELS = {
  waiting: "Waiting",
  running: "Waiting for you",
  pass: "Passed",
  fail: "Failed",
  unavailable: "Not on this machine",
}
const MENU_ITEM = { id: "check-menu-item", title: "Mark this check done", shortcut: "CmdOrCtrl+Shift+M" }
const SHORTCUT = { id: "check-shortcut", accelerator: "CmdOrCtrl+Shift+K" }

export default class extends Controller {
  static targets = ["log", "tally"]
  static values = { deepLink: String }

  connect() {
    this.results = this.load()
    this.stopListening = this.listenToTheShell()

    for (const [id, result] of Object.entries(this.results)) this.show(id, result)
    this.arrivedByDeepLink()
    this.compareSize()
    this.tally()

    // /checks?auto=1 runs what needs nobody, for a run nobody is watching.
    const auto = new URLSearchParams(window.location.search).get("auto")
    if (auto === "1") this.runAll()
    if (auto === "confirm") this.question()
  }

  disconnect() {
    if (this.stopListening) this.stopListening()
  }

  get shell() {
    return window.TurboDesktop
  }

  // ─── The shell does these when asked ────────────────────────────────────

  async runAll() {
    await this.whereAmI()
    await this.clipboard()
    await this.notify()
    await this.setBadge(3)
    await this.addMenuItem()
    await this.registerShortcut()
    await this.packaged()
    await this.inspector()
  }

  async whereAmI() {
    if (!this.present("shell")) return

    const info = await this.shell.getWindowInfo()
    if (!info) return this.mark("shell", "fail", "The shell did not answer.")

    this.mark(
      "shell",
      "pass",
      `Turbo Desktop ${this.shell.version} on ${this.shell.platform} (${info.arch}), ` +
        `window "${info.label}", ${this.size(info)}.`
    )
  }

  async notify() {
    const response = await this.ask("notification", "show", {
      title: "Task Manager",
      body: "This is the notification from the desktop checks.",
    })
    if (!response) return

    if (response.status === "shown") {
      this.mark("notification", "running", "The shell sent it. Did you see it?")
    } else {
      this.refused("notification", response)
    }
  }

  badge(event) {
    return this.setBadge(Number(event.currentTarget.dataset.count))
  }

  async setBadge(count) {
    const response = await this.ask("badge", "set", { count })
    if (!response) return

    if (response.status === "updated") {
      this.mark(
        "badge",
        "running",
        count > 0 ? `Set to ${count}. Is it on the icon?` : "Cleared. Has it gone?"
      )
    } else {
      this.refused("badge", response)
    }
  }

  async addMenuItem() {
    const response = await this.ask("menu-item", "connect", MENU_ITEM)
    if (!response) return

    if (response.status === "registered") {
      this.mark("menu-item", "running", "It is in the Actions menu. Choose it.")
    } else {
      this.refused("menu-item", response)
    }
  }

  async removeMenuItem() {
    const response = await this.ask("menu-item", "unregister", MENU_ITEM)
    if (response) this.say(`menu-item: ${response.status}`)
  }

  async registerShortcut() {
    const response = await this.ask("shortcut", "register", SHORTCUT)
    if (!response) return

    if (response.status === "registered") {
      this.mark("shortcut", "running", "Registered. Switch away and press Cmd/Ctrl+Shift+K.")
    } else {
      this.refused("shortcut", response)
    }
  }

  async unregisterShortcut() {
    const response = await this.ask("shortcut", "unregister", SHORTCUT)
    if (response) this.say(`shortcut: ${response.status}`)
  }

  async clipboard() {
    if (!this.present("clipboard")) return

    const text = "Turbo Desktop check"
    await this.shell.clipboard.writeText(text)
    const read = await this.shell.clipboard.readText()

    if (read === text) {
      this.mark("clipboard", "pass", `Wrote and read back "${text}". Paste it somewhere to see.`)
    } else {
      this.mark("clipboard", "fail", `Wrote "${text}", read back ${JSON.stringify(read)}.`)
    }
  }

  async inspector() {
    if (!this.present("inspector")) return

    // The shell loads it once the page has, so give it a moment.
    for (let tries = 0; tries < 20; tries++) {
      const panel = document.querySelector("[data-turbo-desktop-inspector]")
      if (panel) {
        const open = panel.style.display !== "none"
        return this.mark(
          "inspector",
          "running",
          open
            ? "Loaded, and open: the panel at the bottom right. Is it logging what you press?"
            : "Loaded, and closed. Press Cmd/Ctrl+Shift+D to open it, then Check again."
        )
      }
      await new Promise((resolve) => setTimeout(resolve, 250))
    }

    // Why not, as far as the page can tell.
    const beside = Array.from(document.documentElement.children).map((el) => el.tagName.toLowerCase())
    this.mark(
      "inspector",
      "fail",
      `It did not load. Asked for: ${this.shell._inspectorWanted}. ` +
        `Error: ${this.shell._inspectorError || "none"}. In the page: ${beside.join(", ")}.`
    )
  }

  async devtools() {
    if (!this.present("devtools")) return

    const response = await this.shell.toggleDevTools()
    if (!response) return this.mark("devtools", "fail", "The shell did not answer.")
    if (response.status === "unavailable") return this.refused("devtools", response)

    this.mark("devtools", "running", `The shell says: ${response.status}. Did you see it?`)
  }

  async packaged() {
    if (!this.present("packaged")) return

    const info = await this.shell.getWindowInfo()
    if (!info) return this.mark("packaged", "fail", "The shell did not answer.")

    if (info.development === false) {
      this.mark("packaged", "pass", "Running from a bundle, built for release.")
    } else {
      this.mark("packaged", "running", "This is a development build. Run bin/demo-package and open the app it builds.")
    }
  }

  async question() {
    if (!this.present("confirm")) return

    this.mark("confirm", "running", "Asking. Answer the dialog.")
    const deleted = await this.shell.confirm("Delete this task? (Nothing will be deleted.)", {
      title: "Desktop checks",
      confirm: "Delete",
      cancel: "Keep",
    })

    this.answers = { ...(this.answers || {}), [deleted ? "Delete" : "Keep"]: true }
    const both = this.answers.Delete && this.answers.Keep
    this.mark(
      "confirm",
      both ? "pass" : "running",
      `You chose ${deleted ? "Delete" : "Keep"}.` + (both ? " Both answers seen." : " Ask again and choose the other.")
    )
  }

  // ─── Files by way of a dialog ───────────────────────────────────────────

  chooseFile() {
    return this.choose("open", "Choose a file")
  }

  chooseFolder() {
    return this.choose("open-folder", "Choose a folder")
  }

  async choose(event, title) {
    const picked = await this.ask("file-picker", event, { title })
    if (!picked) return

    if (picked.status === "cancelled") {
      return this.mark("file-picker", "running", "Cancelled, and reported as cancelled. Now pick something.")
    }
    if (picked.status !== "selected") return this.refused("file-picker", picked)

    this.mark("file-picker", "pass", await this.describe([picked.path]))
  }

  async exportTasks() {
    const picked = await this.ask("file-picker", "save", {
      title: "Export tasks",
      defaultName: "tasks.csv",
      filters: [{ name: "CSV", extensions: ["csv"] }],
    })
    if (!picked) return

    if (picked.status === "cancelled") {
      return this.mark("export", "running", "Cancelled. Press Export again and save it somewhere.")
    }
    if (picked.status !== "selected") return this.refused("export", picked)

    const csv = await (await fetch("/tasks.csv")).text()
    const written = await this.shell.fs.write(picked.path, csv)

    if (written && written.status === "ok") {
      const rows = csv.trim().split("\n").length - 1
      this.mark("export", "pass", `${rows} tasks written to ${picked.path}`)
    } else {
      this.mark("export", "fail", `Could not write ${picked.path}: ${written?.error || "no answer"}`)
    }
  }

  // ─── Things the operating system tells the app ──────────────────────────

  dragEntered() {
    this.card("drop").classList.add("drop-target")
  }

  dragLeft() {
    this.card("drop").classList.remove("drop-target")
  }

  async dropped(event) {
    this.dragLeft()
    const paths = event.detail.paths || []
    if (paths.length === 0) return this.mark("drop", "fail", "A drop arrived with no paths.")

    this.mark("drop", "pass", await this.describe(paths))
  }

  async fileOpened(event) {
    const paths = event.detail.paths || []
    if (paths.length === 0) return this.mark("file-open", "fail", "The app was opened with no file.")

    this.mark("file-open", "pass", await this.describe(paths))
  }

  cameBack(event) {
    const { awaySeconds, refreshing } = event.detail
    this.mark(
      "focus",
      "pass",
      `Away for ${Math.round(awaySeconds)}s.` + (refreshing ? " The shell proposed a refresh." : "")
    )
  }

  arrivedByDeepLink() {
    const card = this.card("deep-link")
    if (card.dataset.arrived !== "true") return

    this.mark("deep-link", "pass", `Arrived by ${this.deepLinkValue}.`)
    // To the card the link was about, so that arriving is seen to have worked.
    card.scrollIntoView({ block: "center" })
  }

  async copyDeepLink() {
    if (!this.present("deep-link")) return

    const command = `open "${this.deepLinkValue}"`
    await this.shell.clipboard.writeText(command)
    this.mark("deep-link", "running", `Copied: ${command}`)
  }

  listenToTheShell() {
    const onMessage = (event) => {
      const { component, event: name, data } = event.detail || {}
      if (component === "menu-item" && name === "clicked" && data.id === MENU_ITEM.id) {
        this.mark("menu-item", "pass", "Chosen from the Actions menu.")
      }
      if (component === "shortcut" && name === "triggered" && data.id === SHORTCUT.id) {
        this.mark("shortcut", "pass", `${data.accelerator} pressed.`)
      }
    }

    // The shell delivers native events through the injected bridge. A
    // BridgeComponent per component is the usual way to hear them; one
    // listener for both keeps this page in one piece.
    const unlisten = []
    if (this.shell && this.shell.BridgeComponent) {
      for (const component of ["menu-item", "shortcut"]) {
        const Component = class extends this.shell.BridgeComponent {
          static component = component
          onReceive(message) {
            onMessage({ detail: message })
          }
        }
        const instance = new Component(this.element)
        instance.connect()
        // Not disconnect(): that tells the shell the component is going, and
        // would unregister what the scenario has just registered.
        unlisten.push(() => instance._unlisten && instance._unlisten())
      }
    }

    return () => unlisten.forEach((stop) => stop())
  }

  // ─── Things only a person can judge ─────────────────────────────────────

  saw(event) {
    const { checkId, saw } = event.currentTarget.dataset
    this.mark(checkId, saw === "yes" ? "pass" : "fail", saw === "yes" ? "Seen." : "Not seen.")
  }

  modalOpened() {
    this.mark("modal", "running", "A window should have opened. Is this one still on the checks page?")
  }

  externalFollowed() {
    this.mark("external-link", "running", "Your browser should have opened. Is this window still here?")
  }

  async rememberSize() {
    if (!this.present("window-size")) return

    const info = await this.shell.getWindowInfo()
    if (!info) return

    localStorage.setItem(SIZE, this.size(info))
    this.mark("window-size", "running", `Noted ${this.size(info)}. Quit, open the app again, and come back here.`)
  }

  async compareSize() {
    const noted = localStorage.getItem(SIZE)
    if (!noted || !this.shell) return

    const info = await this.shell.getWindowInfo()
    if (!info) return

    const now = this.size(info)
    if (this.results["window-size"]?.state !== "running") return

    this.mark(
      "window-size",
      now === noted ? "pass" : "fail",
      `Last time ${noted}, now ${now}.`
    )
  }

  // ─── Keeping track ──────────────────────────────────────────────────────

  startOver() {
    localStorage.removeItem(STORE)
    localStorage.removeItem(SIZE)
    this.results = {}
    this.element.querySelectorAll("[data-check]").forEach((card) => {
      this.show(card.dataset.check, { state: "waiting", detail: "" })
    })
    this.logTarget.textContent = ""
    this.tally()
  }

  /** Ask a bridge component, and mark the card when the shell is not there. */
  async ask(component, event, data) {
    if (!this.present(component)) return null

    const response = await this.shell.sendBridgeMessage(component, event, data)
    if (!response) {
      this.mark(component, "fail", "The shell refused the message, or did not answer.")
      return null
    }
    return response
  }

  present(id) {
    if (this.shell) return true

    this.mark(id, "unavailable", "Not running in the desktop app.")
    return false
  }

  refused(id, response) {
    const state = response.status === "unavailable" ? "unavailable" : "fail"
    this.mark(id, state, response.error || `The shell answered "${response.status}".`)
  }

  async describe(paths) {
    const lines = []
    for (const path of paths) {
      const file = await this.shell.fs.read(path)
      if (file && file.status === "ok") {
        lines.push(`${path} — read ${file.content.length} characters`)
      } else {
        const entries = await this.shell.fs.list(path)
        lines.push(
          entries && entries.status === "ok"
            ? `${path} — a folder of ${entries.entries.length}`
            : `${path} — could not be read`
        )
      }
    }
    return lines.join("\n")
  }

  size(info) {
    const scale = info.scaleFactor || 1
    return `${Math.round(info.width / scale)}×${Math.round(info.height / scale)}`
  }

  card(id) {
    return this.element.querySelector(`[data-check="${id}"]`)
  }

  mark(id, state, detail) {
    const result = { state, detail, at: new Date().toISOString() }
    this.results[id] = result
    this.show(id, result)
    this.say(`${id}: ${state} — ${detail}`)
    this.save()
    this.tally()
  }

  show(id, { state, detail }) {
    const card = this.card(id)
    if (!card) return

    card.dataset.state = state
    card.querySelector('[data-role="state"]').textContent = LABELS[state] || state
    card.querySelector('[data-role="detail"]').textContent = detail || ""
  }

  say(line) {
    const time = new Date().toLocaleTimeString()
    this.logTarget.textContent = `${time}  ${line}\n${this.logTarget.textContent}`
  }

  tally() {
    const all = this.element.querySelectorAll("[data-check]").length
    const count = (state) => Object.values(this.results).filter((r) => r.state === state).length
    this.tallyTarget.textContent = `${count("pass")} of ${all} passed` + (count("fail") ? `, ${count("fail")} failed` : "")
  }

  load() {
    try {
      return JSON.parse(localStorage.getItem(STORE)) || {}
    } catch {
      return {}
    }
  }

  save() {
    localStorage.setItem(STORE, JSON.stringify(this.results))

    // Once things have settled, and only the latest: several marks in a row
    // would otherwise race each other to the server, and an early one could
    // land last.
    clearTimeout(this.reporting)
    this.reporting = setTimeout(() => this.report(), 300)
  }

  report() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/checks/report", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({
        platform: this.shell?.platform,
        version: this.shell?.version,
        results: this.results,
      }),
    }).catch(() => {})
  }
}
