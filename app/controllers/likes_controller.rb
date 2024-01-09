class LikesController < ApplicationController
  before_action(
    :require_login,
    only: [
      :create_comment_like,
      :create_post_like,
      :destroy_comment_like,
      :destroy_post_like
    ]
  )

  def create_comment_like
    @like = CommentLike.new(like_params)
    @like.user_id = current_user.id

    save_like!
  end

  def create_post_like
    @like = PostLike.new(like_params)
    @like.user_id = current_user.id

    save_like!
  end

  def destroy_comment_like
    @like = CommentLike.find_by(
      user_id: current_user.id,
      message_id: params[:like][:message_id]
    )

    destroy_like!
  end

  def destroy_post_like
    @like = PostLike.find_by(
      user_id: current_user.id,
      message_id: params[:like][:message_id]
    )

    destroy_like!
  end

  def user_likes
    @user = User.find_by(id: params[:user_id])

    if @user.present?
      render(
        json: {likes: @user.likes(current_user:)},
        status: :ok
      )
    else
      render(
        json: {errors: ["Unable to find user."]},
        status: :not_found
      )
    end
  end

  private

  def save_like!
    if @like.save
      render :show
    else
      render(
        json: {errors: @like.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  def destroy_like!
    if @like.present?
      if @like.destroy
        render :show
      else
        render(
          json: {errors: @like.errors.full_messages},
          status: :unprocessable_entity
        )
      end
    else
      render(
        json: {errors: ["Unable to find like reference."]},
        status: :not_found
      )
    end
  end

  def require_login
    return if logged_in?

    render(
      json: {errors: ["Must be logged in to manage likes."]},
      status: :unauthorized
    )
  end

  def like_params
    params.require(:like).permit(:message_id)
  end
end
