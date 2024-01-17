class UsersController < ApplicationController
  append_before_action :require_login, only: [:update]

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
    @user = User.new(create_user_params)
    if @user.save
      login! @user
      render "sessions/show"
    else
      render(
        json: {errors: @user.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  def update
    if current_user.id.to_s == params[:id]
      @user = current_user

      if @user.update(edit_user_params)
        render :show
      else
        render(
          json: {errors: @user.errors.full_messages},
          status: :unprocessable_entity
        )
      end
    else
      render(
        json: {errors: ["This account is inaccessible"]},
        status: :unauthorized
      )
    end
  end

  private

  def edit_user_params
    params
      .require(:user)
      .permit(
        :display_name,
        :email
      )
  end

  def create_user_params
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
