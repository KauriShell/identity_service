# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  path "/api/v1/auth/sign_in" do
    post "Sign in" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          api_v1_user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string, format: :password }
            },
            required: %w[email password]
          }
        },
        required: ["api_v1_user"]
      }

      response "200", "signed in" do
        let(:body) do
          {
            api_v1_user: {
              email: create(:user, password: "Password1234!", confirmed_at: Time.current).email,
              password: "Password1234!"
            }
          }
        end

        run_test!
      end

      response "401", "invalid credentials or unconfirmed email" do
        let(:body) do
          {
            api_v1_user: {
              email: "missing@example.com",
              password: "WrongPassword123!"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/sign_out" do
    delete "Sign out" do
      tags "Auth"
      description "Revokes the current access JWT (denylist) and revokes all refresh tokens for the user."
      security [bearerAuth: []]
      produces "application/json"

      response "204", "signed out" do
        let(:Authorization) { auth_headers(user)["Authorization"] }
        let(:user) { create(:user) }

        run_test!
      end
    end
  end

  path "/api/v1/auth/sign_up" do
    post "Register" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          api_v1_user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string },
              password_confirmation: { type: :string }
            },
            required: %w[email password password_confirmation]
          }
        },
        required: ["api_v1_user"]
      }

      response "200", "registered" do
        let(:body) do
          {
            api_v1_user: {
              email: "swagger_new_#{SecureRandom.hex(4)}@example.com",
              password: "Password1234!",
              password_confirmation: "Password1234!"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/refresh" do
    post "Refresh tokens" do
      tags "Auth"
      description "Exchange a refresh token for new access and refresh tokens. No Bearer header required."
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          refreshToken: { type: :string, description: "Opaque refresh token from sign-in or prior refresh" }
        },
        required: ["refreshToken"]
      }

      response "200", "tokens issued" do
        let(:body) do
          { refreshToken: RefreshTokenIssuer.call(user).token }
        end
        let(:user) { create(:user) }

        run_test!
      end

      response "401", "invalid or expired refresh token" do
        let(:body) { { refreshToken: SecureRandom.hex(32) } }

        run_test!
      end
    end
  end

  path "/api/v1/auth/password" do
    post "Request password reset" do
      tags "Auth"
      description "Sends reset instructions when paranoid mode is off; with paranoid enabled, " \
                  "response is the same whether or not the email exists."
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          api_v1_user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email }
            },
            required: ["email"]
          }
        },
        required: ["api_v1_user"]
      }

      response "200", "instructions sent (or generic success if paranoid)" do
        let(:body) { { api_v1_user: { email: create(:user).email } } }

        run_test!
      end
    end

    patch "Reset password" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          api_v1_user: {
            type: :object,
            properties: {
              reset_password_token: { type: :string },
              password: { type: :string },
              password_confirmation: { type: :string }
            },
            required: %w[reset_password_token password password_confirmation]
          }
        },
        required: ["api_v1_user"]
      }

      response "200", "password updated" do
        let(:user) { create(:user, password: "Password1234!") }
        let(:body) do
          raw, enc = Devise.token_generator.generate(User, :reset_password_token)
          user.update_columns(reset_password_token: enc, reset_password_sent_at: Time.current)
          {
            api_v1_user: {
              reset_password_token: raw,
              password: "NewPassword1234!",
              password_confirmation: "NewPassword1234!"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/confirmation" do
    get "Confirm email" do
      tags "Auth"
      produces "application/json"
      parameter name: :confirmation_token, in: :query, type: :string, required: true,
                description: "Token from the confirmation email"

      response "200", "confirmed" do
        let(:confirmation_token) do
          user = User.create!(
            email: "swagger_confirm_#{SecureRandom.hex(4)}@example.com",
            password: "Password1234!",
            password_confirmation: "Password1234!",
            jti: SecureRandom.uuid,
            confirmed_at: nil
          )
          raw, enc = Devise.token_generator.generate(User, :confirmation_token)
          user.update_columns(confirmation_token: enc, confirmation_sent_at: Time.current)
          raw
        end

        run_test!
      end
    end

    post "Resend confirmation" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          api_v1_user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email }
            },
            required: ["email"]
          }
        },
        required: ["api_v1_user"]
      }

      response "200", "confirmation email enqueued" do
        let(:body) { { api_v1_user: { email: create(:user, confirmed_at: nil).email } } }

        run_test!
      end
    end
  end

  path "/api/v1/auth/unlock" do
    get "Unlock account (link from email)" do
      tags "Auth"
      produces "application/json"
      parameter name: :unlock_token, in: :query, type: :string, required: true

      response "422", "unlock token invalid" do
        let(:unlock_token) { "not-a-valid-unlock-token" }

        run_test!
      end
    end

    post "Request unlock email" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          api_v1_user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email }
            },
            required: ["email"]
          }
        },
        required: ["api_v1_user"]
      }

      response "200", "unlock email sent (or generic success)" do
        let(:body) { { api_v1_user: { email: create(:user).email } } }

        run_test!
      end
    end
  end
end
