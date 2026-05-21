# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM", "TrustBridge <noreply@trustbridge.local>")

  def transactional
    @body = params[:body]
    mail(to: params[:to], subject: params[:subject])
  end
end
