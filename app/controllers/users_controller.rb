class UsersController < ApplicationController
  def show
    @user = User
            .includes(:subscriptions, :follows)
            .find_by(username: params[:username])

    if @user.present?
      render :show
    else
      render(
        json: {errors: ["This account doesn't exist"]},
        status: :not_found
      )
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_email!
      login! @user
      render "sessions/show"
    else
      render(
        json: {errors: @user.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  private

  def user_params
    params
      .require(:user)
      .permit(
        :username,
        :display_name,
        :email,
        :password,
        :password_confirmation
      )
  end
end
