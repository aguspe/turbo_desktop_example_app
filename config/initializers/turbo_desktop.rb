# Turbo Desktop Path Configuration
#
# This file configures how the Turbo Desktop native shell presents your routes.
# The path configuration follows the same pattern as Hotwire Native
# (turbo-ios / turbo-android) — JSON rules that map URL patterns to
# presentation styles.
#
# The desktop shell fetches this configuration from:
#   GET /turbo-desktop/path-configuration.json
#
# Presentations:
#   "default"    — Navigate in the current window (standard Turbo Drive)
#   "modal"      — Open in a modal/sheet window (800x600)
#   "new_window" — Open in a separate full window (1200x800)
#   "replace"    — Replace the current page (no back button)
#   "native"     — Route to a fully native screen (handled by Rust/Tauri)
#   "none"       — Do nothing (handled by a bridge component)

TurboDesktop.configure do |config|
  config.path_configuration = {
    settings: {
      screenshots_enabled: false
    },
    rules: [
      # Default: all pages navigate in the current window
      # This is the catch-all rule — Turbo Drive handles navigation normally
      { patterns: ["/"], properties: { presentation: "default" } },

      # Forms open in a modal window
      # Any URL ending in /new or /edit will open in a native modal overlay.
      # This gives forms a focused, dialog-like feel — just like on mobile.
      { patterns: ["/new$", "/edit$"], properties: { presentation: "modal" } },

      # Task detail pages open in a new window
      # Uncomment this if you want task details to open in a separate window:
      # { patterns: ["/tasks/\\d+$"], properties: { presentation: "new_window" } },
    ]
  }
end
