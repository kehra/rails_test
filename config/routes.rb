Rails.application.routes.draw do
  concern :commentable do
    resources :comments, only: %i[ create destroy ], shallow: true
  end

  direct :help_center do
    route_for(:docs_preview)
  end

  resolve("Profile") { [ :profile ] }

  resource :session, only: %i[ new create destroy ]
  resources :signups, only: %i[ new create ]
  resources :organizations
  resources :projects
  resources :tasks, concerns: :commentable do
    get :export, on: :collection
    get :export_file, on: :collection
    get :stream, on: :collection, to: "streams#tasks"
    delete "files/:signed_id/purge", on: :member, action: :purge_file, as: :purge_file
    delete "files/:signed_id/purge_later", on: :member, action: :purge_file_later, as: :purge_file_later

    resources :audit_comments, controller: "comments", only: :destroy,
      shallow: true,
      shallow_path: "c",
      shallow_prefix: "c"
  end
  scope path_names: { new: "neu", edit: "bearbeiten" } do
    resources :localized_projects, controller: "projects", only: %i[ new edit ]
  end
  resource :profile, only: :show
  get "docs/preview", to: "docs#preview"
  get "docs/debug_dump", to: "docs#debug_dump"
  get "docs/etag", to: "docs#etag"
  get "docs/about", to: "docs#about", defaults: { format: :json }
  get "docs/feed", to: "docs#feed", defaults: { format: :atom }
  get "docs/files/*path", to: "docs#files"
  draw :demo

  namespace :api do
    get "ping", to: "pings#show"
    get "metal_ping", to: "metal_pings#show"
  end
  namespace :admin do
    get "diagnostics", to: "diagnostics#show"
  end
  constraints organization_id: /\d+/ do
    resources :organizations, only: [] do
      resources :projects, only: %i[ index new create ], controller: "projects"
    end
  end

  constraints project_id: /\d+/ do
    resources :projects, only: [] do
      resources :tasks, only: %i[ index new create ], controller: "tasks" do
        get :export, on: :collection
      end
    end
  end

  get "dashboard", to: "dashboard#index"
  get "home", to: redirect("/dashboard")
  mount Teamhub::SampleEngine => "/engine"
  match "/rack_echo", to: RackEchoApp, via: :all
  root "dashboard#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
