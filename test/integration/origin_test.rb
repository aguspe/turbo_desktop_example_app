require "test_helper"

class OriginTest < ActionDispatch::IntegrationTest
  DESKTOP = { "User-Agent" => "Turbo Desktop/0.2.4 (macOS; aarch64)" }.freeze
  BROWSER = { "User-Agent" => "Mozilla/5.0 (Macintosh) Safari/605.1.15" }.freeze

  test "the badge says which shell, platform and architecture the request came from" do
    get root_path, headers: DESKTOP

    assert_select ".origin summary", /Desktop/
    assert_select ".origin summary", /macOS/
    assert_select ".origin summary", /aarch64/
    assert_select ".origin summary", /0\.2\.4/
  end

  test "opening it shows where the request came from, in full" do
    get root_path, headers: DESKTOP

    assert_select ".origin-details" do
      assert_select "dt", "User agent"
      assert_select "dd", "Turbo Desktop/0.2.4 (macOS; aarch64)"
      assert_select "dt", "Shell"
      assert_select "dt", "Served by"
      assert_select "dd", "http://www.example.com"
      assert_select "dt", "Rails"
      assert_select "dt", "Ruby"
      assert_select "dt", "Window"
    end
  end

  test "a browser is told it is a browser, and what it said it was" do
    get root_path, headers: BROWSER

    assert_select ".origin summary", /Web browser/
    assert_select ".origin-details dd", /Safari/
    assert_select ".origin-details dt", { text: "Shell", count: 0 }
  end

  test "the dock badge is the number of tasks still to do" do
    Task.create!(title: "One", priority: "low", completed: false)
    Task.create!(title: "Two", priority: "low", completed: false)
    Task.create!(title: "Done", priority: "low", completed: true)

    get root_path, headers: DESKTOP

    assert_select "[data-turbo-desktop-bridge='badge'][data-turbo-desktop-bridge-count='2']", 1
  end

  test "a browser has no dock to badge" do
    get root_path, headers: BROWSER

    assert_select "[data-turbo-desktop-bridge='badge']", 0
  end
end
