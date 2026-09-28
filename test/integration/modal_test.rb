require "test_helper"

# A form opened in a modal has a window of its own around it. The app's
# navigation and footer belong to the main window.
class ModalTest < ActionDispatch::IntegrationTest
  DESKTOP = { "User-Agent" => "Turbo Desktop/0.2.4 (macOS; aarch64)" }.freeze
  BROWSER = { "User-Agent" => "Mozilla/5.0 (Macintosh) Safari/605.1.15" }.freeze

  test "a new task's form has no navigation in the desktop app" do
    get new_task_path, headers: DESKTOP

    assert_response :success
    assert_select "nav.navbar", 0
    assert_select "footer", 0
    assert_select "form"
  end

  test "editing a task has none either" do
    task = Task.create!(title: "Record the demo", priority: "high")

    get edit_task_path(task), headers: DESKTOP

    assert_select "nav.navbar", 0
    assert_select "form"
  end

  test "a form sent back with its mistakes is still in its modal" do
    post tasks_path, params: { task: { title: "", priority: "high" } }, headers: DESKTOP

    assert_response :unprocessable_entity
    assert_select "nav.navbar", 0
    assert_select "form"
  end

  test "the same form in a browser is a page like any other" do
    get new_task_path, headers: BROWSER

    assert_select "nav.navbar", 1
    assert_select "footer", 1
  end

  test "an ordinary page keeps its navigation in the desktop app" do
    get tasks_path, headers: DESKTOP

    assert_select "nav.navbar", 1
  end

  test "a modal page still says which window it is, for the shell" do
    get new_task_path, headers: DESKTOP

    assert_select "body.in-modal", 1
  end
end
