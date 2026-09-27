Rails.application.routes.draw do
  resources :tasks do
    collection do
      post :import
    end
  end

  # Mount the Turbo Desktop engine — this serves the path configuration JSON
  # at /turbo-desktop/path-configuration.json for the desktop shell to consume
  mount TurboDesktop::Engine => "/turbo-desktop"

  # Answers 200 once the app has booted. Launch scripts and uptime monitors
  # wait on this.
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"
end
