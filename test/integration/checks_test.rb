require "test_helper"

class ChecksTest < ActionDispatch::IntegrationTest
  DESKTOP = { "User-Agent" => "Turbo Desktop/0.2.4 (macOS; aarch64)" }.freeze
  BROWSER = { "User-Agent" => "Mozilla/5.0 (Macintosh) Safari/605.1.15" }.freeze

  # One per scenario that no automated test can reach, because it involves
  # the operating system itself.
  SCENARIOS = %w[
    shell notification badge menu-item shortcut clipboard inspector devtools
    file-picker export
    drop file-open deep-link modal external-link
    focus window-size quit packaged
  ].freeze

  test "the page lists every scenario" do
    get checks_path, headers: DESKTOP

    assert_response :success
    SCENARIOS.each do |scenario|
      assert_select "[data-check='#{scenario}']", 1, "no card for #{scenario}"
    end
  end

  test "every scenario says what to do and what to expect" do
    get checks_path, headers: DESKTOP

    SCENARIOS.each do |scenario|
      assert_select "[data-check='#{scenario}'] .check-steps li", { minimum: 1 }, "#{scenario} has no steps"
      assert_select "[data-check='#{scenario}'] .check-expect", 1, "#{scenario} does not say what to expect"
    end
  end

  test "each way of handing the app a file has a place to do it" do
    get checks_path, headers: DESKTOP

    assert_select "[data-check='drop'] .check-dropzone", 1
    assert_select "[data-check='file-open'] .check-dropzone", 1
    assert_select "[data-check='file-picker'] button", { minimum: 2 }
  end

  test "the card says where to find what it puts in the menu bar" do
    get checks_path, headers: DESKTOP

    assert_select "[data-check='menu-item'] .check-steps", /right of the menu bar/i
  end

  test "the card says a Focus mode hides notifications" do
    get checks_path, headers: DESKTOP

    assert_select "[data-check='notification'] .check-steps", /Focus/
  end

  test "a deep link is recognised when it lands" do
    get checks_path(from: "deep-link"), headers: DESKTOP

    assert_select "[data-check='deep-link'][data-arrived='true']"
  end

  test "a browser is told the checks need the desktop app" do
    get checks_path, headers: BROWSER

    assert_response :success
    assert_select ".web-banner", /desktop app/i
  end

  test "the checks are linked from the navigation inside the desktop app only" do
    get root_path, headers: DESKTOP
    assert_select "a.nav-link[href='#{checks_path}']"

    get root_path, headers: BROWSER
    assert_select "a.nav-link[href='#{checks_path}']", 0
  end

  test "results are kept, so a run can be read afterwards" do
    report = Rails.root.join("tmp/desktop-checks.json")
    report.delete if report.exist?

    post checks_report_path,
         params: { platform: "macos", results: { badge: { state: "pass", detail: "updated" } } },
         as: :json,
         headers: DESKTOP

    assert_response :no_content
    saved = JSON.parse(report.read)
    assert_equal "macos", saved["platform"]
    assert_equal "pass", saved.dig("results", "badge", "state")
  ensure
    report&.delete if report&.exist?
  end
end
