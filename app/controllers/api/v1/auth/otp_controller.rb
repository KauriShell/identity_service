# frozen_string_literal: true

module Api
  module V1
    module Auth
      class OtpController < BaseController
        skip_before_action :authenticate_api_v1_user!

        def send_code
          phone = normalize_phone(params.require(:phone))
          return render_error(status: :unprocessable_entity, title: "Unprocessable Entity", detail: "Invalid phone number", source: :invalid_phone) unless phone

          otp = OtpCode.active.where(phone_number: phone).order(created_at: :desc).first
          if otp.present? && otp.last_sent_at > OtpCode::RESEND_COOLDOWN.ago
            retry_after = (otp.last_sent_at + OtpCode::RESEND_COOLDOWN - Time.current).ceil
            return render json: {
              errors: [{
                status: "429",
                title: "Too Many Requests",
                detail: "Please wait before requesting another OTP",
                source: "rate_limit_exceeded",
                retry_after_seconds: retry_after
              }]
            }, status: :too_many_requests
          end

          code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
          digest = Digest::SHA256.hexdigest("#{phone}:#{code}")
          otp = OtpCode.create!(
            phone_number: phone,
            code_digest: digest,
            expires_at: OtpCode::CODE_TTL.from_now,
            last_sent_at: Time.current
          )

          payload = {
            data: {
              phone_masked: mask_phone(phone),
              expires_in_seconds: OtpCode::CODE_TTL.to_i,
              resend_after_seconds: OtpCode::RESEND_COOLDOWN.to_i
            }
          }
          if Rails.env.test?
            payload[:meta] = { debug_otp: code }
          end
          render json: payload, status: :accepted
        end

        def verify
          phone = normalize_phone(params.require(:phone))
          code = params.require(:otp_code).to_s.strip
          return render_error(status: :unprocessable_entity, title: "Unprocessable Entity", detail: "Invalid phone number", source: :invalid_phone) unless phone

          otp = OtpCode.where(phone_number: phone).order(created_at: :desc).first
          return render_error(status: :unauthorized, title: "Unauthorized", detail: "OTP is invalid", source: :invalid_otp) if otp.nil?
          return render_error(status: :gone, title: "Gone", detail: "OTP has expired", source: :otp_expired) if otp.expired?
          return render_error(status: :unauthorized, title: "Unauthorized", detail: "OTP already used", source: :invalid_otp) if otp.consumed?
          if otp.over_attempt_limit?
            return render_error(status: :too_many_requests, title: "Too Many Requests", detail: "Too many OTP attempts", source: :rate_limit_exceeded)
          end

          submitted_digest = Digest::SHA256.hexdigest("#{phone}:#{code}")
          unless ActiveSupport::SecurityUtils.secure_compare(submitted_digest, otp.code_digest)
            otp.increment!(:attempts_count)
            return render_error(status: :unauthorized, title: "Unauthorized", detail: "OTP is invalid", source: :invalid_otp)
          end

          otp.update!(consumed_at: Time.current)
          user, is_new = find_or_create_phone_user!(phone)
          refresh = RefreshTokenIssuer.call(user)
          access_token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

          render json: {
            data: UserPrivateSerializer.new(user).serializable_hash[:data],
            meta: {
              accessToken: access_token,
              expiresIn: Rails.configuration.x.access_token_ttl.to_i,
              refreshToken: refresh.token,
              refreshTokenExpiresAt: refresh.expires_at.iso8601,
              isNewUser: is_new
            }
          }, status: :ok
        end

        private

        def normalize_phone(raw)
          digits = raw.to_s.gsub(/\D/, "")
          return "254#{digits[1..]}" if digits.start_with?("0") && digits.length == 10
          return "254#{digits}" if digits.length == 9 && digits.start_with?("7")
          return digits if digits.start_with?("254") && digits.length == 12

          nil
        end

        def mask_phone(phone)
          "254#{phone[-9, 2]}*****#{phone[-2, 2]}"
        end

        def find_or_create_phone_user!(phone)
          user = User.find_by(phone_number: phone)
          return [user, false] if user

          email = "member-#{phone}-#{SecureRandom.hex(3)}@trustbridge.local"
          password = SecureRandom.hex(16)
          user = User.create!(
            phone_number: phone,
            email: email,
            password: password,
            password_confirmation: password,
            confirmed_at: Time.current,
            role: :member,
            status: :active
          )
          [user, true]
        end
      end
    end
  end
end
