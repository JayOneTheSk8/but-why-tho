class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_email!
      render :show
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
