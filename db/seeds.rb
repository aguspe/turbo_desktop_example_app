# Sample tasks to demonstrate the app
tasks = [
  { title: "Set up Turbo Desktop", description: "Install the turbo_desktop-rails gem and configure the desktop shell.", priority: "high", completed: true },
  { title: "Configure path rules", description: "Define which routes open as modals, new windows, or default navigation.", priority: "high", completed: true },
  { title: "Add bridge components", description: "Use bridge components to trigger native notifications and menu items.", priority: "medium", completed: false },
  { title: "Style the dashboard", description: "Create a clean dashboard that looks great in both web and desktop.", priority: "medium", completed: false },
  { title: "Test on all platforms", description: "Build and test on macOS, Windows, and Linux.", priority: "low", completed: false },
  { title: "Write documentation", description: "Document the setup process and key features for other developers.", priority: "low", completed: false },
]

tasks.each { |attrs| Task.create!(attrs) }

puts "Created #{tasks.size} sample tasks."
