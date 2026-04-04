Rails.application.routes.draw do
  resources :tasks

  # Mount the Turbo Desktop engine — this serves the path configuration JSON
  # at /turbo-desktop/path-configuration.json for the desktop shell to consume
  mount TurboDesktop::Engine => "/turbo-desktop"

  root "dashboard#index"
end
