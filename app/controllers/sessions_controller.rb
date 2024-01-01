class SessionsController < ApplicationController
  def create
    @user = User.find_by_credentials(
      params[:user][:login],
      params[:user][:password]
    )

    if @user.present?
      login! @user
      render :show
    else
      render(
        json: {errors: ["Incorrect email/username or password"]},
        status: :unauthorized
      )
    end
  end

  def destroy
    if current_user
      logout!
      head :ok
    else
      render(
        json: {errors: ["No user logged in"]},
        status: :not_found
      )
    end
  end
end
