# Where a request came from, for the badge in the navigation.
module OriginHelper
  PLATFORMS = { "macos" => "macOS", "windows" => "Windows", "linux" => "Linux" }.freeze

  # The shell's version, from the user agent it sends:
  # "Turbo Desktop/0.2.4 (macOS; aarch64)".
  def turbo_desktop_version
    request.user_agent.to_s[%r{Turbo Desktop/([\w.]+)}, 1]
  end

  def origin_platform
    PLATFORMS.fetch(turbo_desktop_platform.to_s, turbo_desktop_platform.to_s.presence || "Unknown")
  end

  # Whether this page is being shown in a modal window. The gem knows from
  # the path configuration; a form sent back with its mistakes is rendered
  # at the address it was posted to, which no rule names, and is still in
  # the modal it was opened in.
  def in_a_modal?
    return false unless turbo_desktop_app?

    turbo_desktop_modal? || %w[create update].include?(action_name)
  end

  # What the badge says at a glance.
  def origin_summary
    return "Web browser" unless turbo_desktop_app?

    [ "Desktop", origin_platform, turbo_desktop_arch, turbo_desktop_version && "shell #{turbo_desktop_version}" ]
      .compact.join(" · ")
  end

  # What it says when opened, as pairs of what and which.
  def origin_details
    details = [ [ "User agent", request.user_agent.presence || "None sent" ] ]

    if turbo_desktop_app?
      details << [ "Shell", "Turbo Desktop #{turbo_desktop_version}" ]
      details << [ "Platform", "#{origin_platform} (#{turbo_desktop_arch})" ]
    end

    details + [
      [ "Served by", request.base_url ],
      [ "Rails", "#{Rails.version}, #{Rails.env}" ],
      [ "Ruby", RUBY_VERSION ],
      [ "Gem", "turbo_desktop-rails #{TurboDesktop::VERSION}" ]
    ]
  end
end
