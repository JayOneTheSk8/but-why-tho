class PostsController < ApplicationController
  before_action :require_login, only: [:create, :update, :destroy]

  def index
    @posts = Post.includes(:author).order(created_at: :desc)
    render :index
  end

  def show
    id = params[:id]
    @post = Post.includes(:author).find_by(id:)

    if @post.present?
      render :show
    else
      render(
        json: {errors: [not_found_post_error_message(id)]},
        status: :not_found
      )
    end
  end

  def create
    @post = Post.new(post_params)
    @post.author_id = current_user.id

    if @post.save
      render :show
    else
      render(
        json: {errors: @post.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  def update
    id = params[:id]
    @post = Post.includes(:author).find_by(id:)

    if @post.present?
      if @post.author_id == current_user.id
        if @post.update(post_params)
          render :show
        else
          render(
            json: {errors: @post.errors.full_messages},
            status: :unprocessable_entity
          )
        end
      else
        render(
          json: {errors: ["Cannot update other's posts."]},
          status: :unauthorized
        )
      end
    else
      render(
        json: {errors: [not_found_post_error_message(id)]},
        status: :not_found
      )
    end
  end

  def destroy
    id = params[:id]
    @post = Post.find_by(id:)

    if @post.present?
      if @post.author_id == current_user.id
        if @post.destroy
          render :show
        else
          render(
            json: {errors: @post.errors.full_messages},
            status: :unprocessable_entity
          )
        end
      else
        render(
          json: {errors: ["Cannot delete other's posts."]},
          status: :unauthorized
        )
      end
    else
      render(
        json: {errors: [not_found_post_error_message(id)]},
        status: :not_found
      )
    end
  end

  def user_posts
    @posts = Post
             .includes(:author)
             .where(author_id: params[:user_id])
             .order(created_at: :desc)

    render :index
  end

  private

  def require_login
    return if logged_in?

    render(
      json: {errors: ["Must be logged in to manage posts."]},
      status: :unauthorized
    )
  end

  def post_params
    params.require(:post).permit(:text)
  end

  def not_found_post_error_message(id)
    "Unable to find Post at given ID: #{id}"
  end
end
