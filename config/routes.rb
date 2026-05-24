Rails.application.routes.draw do
  # Platform health probes (Railway, Render, Fly, k8s) often hit / or /up
  root to: redirect("/api/v1/health")
  get "/up", to: redirect("/api/v1/health")

  namespace :api do
    namespace :v1 do
      devise_for :users,
                 path: "auth",
                 defaults: { format: :json },
                 path_names: { sign_in: "sign_in", sign_out: "sign_out", registration: "sign_up" }

      devise_scope :user do
        post "auth/refresh", to: "auth/refresh_tokens#create"
        post "auth/send_otp", to: "auth/otp#send_code"
        post "auth/verify_otp", to: "auth/otp#verify"
        get "auth/me", to: "auth/me#show"
      end

      resources :users, only: %i[index show update destroy] do
        member do
          get :permissions
        end
      end

      namespace :internal do
        get "users/:id", to: "users#show"
        post "notifications", to: "notifications#create"
        post "emails", to: "emails#create"
      end

      namespace :admin do
        get "settings/jobs", to: "settings#jobs"
        get "settings/kyc-tiers", to: "settings#kyc_tiers"
        patch "settings/kyc-tiers/:tier", to: "settings#update_kyc_tier"
      end

      post "kyc/submit", to: "kyc#submit"
      get "kyc/status", to: "kyc#status"
      get "kyc", to: "kyc#index"
      patch "kyc/:id/review", to: "kyc#review"

      resources :service_tenants
      resources :notifications, only: [:index] do
        member do
          patch :read
        end
        collection do
          patch :read_all
        end
      end
      resources :payout_accounts, only: %i[index create update destroy] do
        member do
          patch :set_primary
        end
      end
      resources :devices, only: %i[create destroy]

      get "health", to: "health#show"
    end
  end

  if defined?(Rswag::Api::Engine)
    mount Rswag::Api::Engine => "/api-docs"
    mount Rswag::Ui::Engine => "/api-docs"
  end

  if defined?(MissionControl::Jobs::Engine)
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end
end
