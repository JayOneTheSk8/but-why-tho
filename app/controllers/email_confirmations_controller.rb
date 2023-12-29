class EmailConfirmationsController < ApplicationController
  def edit
    @user = User.find_signed(params[:confirmation_token], purpose: :confirm_email)

    if @user.present?
      @user.confirm!
      head :ok
    else
      render(
        json: {errors: ["Unable to confirm user with token"]},
        status: :not_found
      )
    end
  end

  def create
    @user = User.unconfirmed.find_by(email: params[:user][:email].downcase)

    if @user.present?
      @user.send_confirmation_email!
      head :ok
    else
      render(
        json: {errors: ["Unable to find user to send confirmation"]},
        status: :not_found
      )
    end
  end
end
