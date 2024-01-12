class ApplicationController < ActionController::API
  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= User.find_by(session_token: session[:session_token])
  end

  def login!(user)
    session[:session_token] = user.reset_session_token!
  end

  def logged_in?
    !!current_user
  end

  def logout!
    current_user&.reset_session_token!
    session[:session_token] = nil
  end

  private

  def require_login
    return if logged_in?

    render(
      json: {
        errors: [
          "Must be logged in to manage #{self.class.name.gsub('Controller', '').downcase}."
        ]
      },
      status: :unauthorized
    )
  end
end
