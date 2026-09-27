# The things no automated test can reach, because they involve the operating
# system itself: a file dragged from the Finder, a notification appearing, a
# shortcut pressed while another app is in front.
#
# Each scenario says what to do and what to expect, and marks itself when the
# app sees it happen. Open it in the desktop app, from the Checks link.
class ChecksController < ApplicationController
  REPORT = Rails.root.join("tmp/desktop-checks.json")

  # The scheme is the app's name, as the CLI derived it.
  DEEP_LINK = "task-manager://checks?from=deep-link".freeze

  def index
    @deep_link = DEEP_LINK
    @arrived_by_deep_link = params[:from] == "deep-link"
  end

  # Kept on disk so a run can be read afterwards, and compared between
  # platforms.
  def report
    REPORT.write(JSON.pretty_generate(
      "platform" => params[:platform],
      "version" => params[:version],
      "reported_at" => Time.current.iso8601,
      "results" => params.fetch(:results, {}).to_unsafe_h
    ))

    head :no_content
  end
end
