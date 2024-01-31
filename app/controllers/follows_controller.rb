class FollowsController < ApplicationController
  append_before_action :require_login, only: [:create, :destroy]

  def create
    @follow = Follow.new(follow_params)
    @follow.follower_id = current_user.id

    if @follow.save
      render :show
    else
      render(
        json: {errors: @follow.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  def destroy
    @follow = Follow.find_by(
      follower_id: current_user.id,
      followee_id: params[:follow][:followee_id]
    )

    if @follow.present?
      if @follow.destroy
        render :show
      else
        render(
          json: {errors: @follow.errors.full_messages},
          status: :unprocessable_entity
        )
      end
    else
      render(
        json: {errors: ["Unable to find follow reference."]},
        status: :not_found
      )
    end
  end

  def followed_users
    @user = User.find_by(username: params[:username])

    if @user.present?
      @followed_users = @user.followed_users

      @users_following_current_user =
        if logged_in?
          Follow
            .where(
              follower_id: @followed_users.pluck(:id),
              followee_id: current_user.id
            )
            .pluck(:follower_id)
            .to_set
        else
          Set.new
        end

      @current_user_following_users =
        if logged_in?
          Follow
            .where(
              followee_id: @followed_users.pluck(:id),
              follower_id: current_user.id
            )
            .pluck(:followee_id)
            .to_set
        else
          Set.new
        end

      render :followed_users
    else
      render(
        json: {errors: ["Unable to find user."]},
        status: :not_found
      )
    end
  end

  def followers
    @user = User.find_by(username: params[:username])

    if @user.present?
      @followers = @user.followers

      @users_following_current_user =
        if logged_in?
          Follow
            .where(
              follower_id: @followers.pluck(:id),
              followee_id: current_user.id
            )
            .pluck(:follower_id)
            .to_set
        else
          Set.new
        end

      @current_user_following_users =
        if logged_in?
          Follow
            .where(
              followee_id: @followers.pluck(:id),
              follower_id: current_user.id
            )
            .pluck(:followee_id)
            .to_set
        else
          Set.new
        end

      render :followers
    else
      render(
        json: {errors: ["Unable to find user."]},
        status: :not_found
      )
    end
  end

  private

  def follow_params
    params.require(:follow).permit(:followee_id)
  end
end
