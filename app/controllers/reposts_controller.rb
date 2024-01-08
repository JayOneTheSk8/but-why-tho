class RepostsController < ApplicationController
  before_action(
    :require_login,
    only: [
      :create_comment_repost,
      :create_post_repost,
      :destroy_comment_repost,
      :destroy_post_repost
    ]
  )

  def create_comment_repost
    @repost = CommentRepost.new(repost_params)
    @repost.user_id = current_user.id

    save_repost!
  end

  def create_post_repost
    @repost = PostRepost.new(repost_params)
    @repost.user_id = current_user.id

    save_repost!
  end

  def destroy_comment_repost
    @repost = CommentRepost.find_by(
      user_id: current_user.id,
      message_id: params[:repost][:message_id]
    )

    destroy_repost!
  end

  def destroy_post_repost
    @repost = PostRepost.find_by(
      user_id: current_user.id,
      message_id: params[:repost][:message_id]
    )

    destroy_repost!
  end

  private

  def save_repost!
    if @repost.save
      render :show
    else
      render(
        json: {errors: @repost.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  def destroy_repost!
    if @repost.present?
      if @repost.destroy
        render :show
      else
        render(
          json: {errors: @repost.errors.full_messages},
          status: :unprocessable_entity
        )
      end
    else
      render(
        json: {errors: ["Unable to find repost reference."]},
        status: :not_found
      )
    end
  end

  def require_login
    return if logged_in?

    render(
      json: {errors: ["Must be logged in to manage reposts."]},
      status: :unauthorized
    )
  end

  def repost_params
    params.require(:repost).permit(:message_id)
  end
end
