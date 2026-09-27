require "test_helper"

class SmokeTest < ActionDispatch::IntegrationTest
  DESKTOP = { "User-Agent" => "Turbo Desktop/0.2.3 (macOS; aarch64)" }.freeze
  BROWSER = { "User-Agent" => "Mozilla/5.0 (Macintosh) Safari/605.1.15" }.freeze

  test "the gem in use has the Dev Inspector fix" do
    assert_operator Gem::Version.new(TurboDesktop::VERSION), :>=, Gem::Version.new("0.2.3")
  end

  test "the health check answers, so a launcher can tell the server is up" do
    get "/up"

    assert_response :success
  end

  test "the dashboard renders" do
    get root_path, headers: BROWSER

    assert_response :success
    assert_includes response.body, "Dashboard"
  end

  test "the desktop banner shows inside the shell" do
    get root_path, headers: DESKTOP

    assert_includes response.body, "Desktop Features Active"
  end

  test "the desktop banner is hidden in a browser" do
    get root_path, headers: BROWSER

    assert_not_includes response.body, "Desktop Features Active"
  end

  test "the task list shows a task" do
    Task.create!(title: "Record the demo", priority: "high")

    get tasks_path, headers: BROWSER

    assert_response :success
    assert_includes response.body, "Record the demo"
  end

  test "forms are routed to a modal" do
    get "/turbo-desktop/path-configuration.json"

    assert_response :success
    modal = response.parsed_body["rules"].find { |rule| rule.dig("properties", "presentation") == "modal" }
    assert_equal [ "/new$", "/edit$" ], modal["patterns"]
  end

  test "nothing is routed to DOOM" do
    get "/turbo-desktop/path-configuration.json"

    patterns = response.parsed_body["rules"].flat_map { |rule| rule["patterns"] }
    assert_not_includes patterns, "/doom"
  end
end
