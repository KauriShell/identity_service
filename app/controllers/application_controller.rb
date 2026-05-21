class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include Devise::Controllers::Helpers
  respond_to :json
end
