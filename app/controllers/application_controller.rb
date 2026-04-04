class ApplicationController < ActionController::Base
  # The turbo_desktop-rails gem automatically includes detection helpers:
  #
  #   turbo_desktop_app?      — true if request comes from Turbo Desktop
  #   turbo_desktop_platform  — "macos", "windows", "linux", or nil
  #   turbo_desktop_arch      — "aarch64", "x86_64", or nil
  #
  # These are available in all controllers and views automatically.
end
