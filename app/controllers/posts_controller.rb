class PostsController < ApplicationController
  before_action(
    :require_login,
    only: [:create, :update, :destroy, :front_page_following]
  )

  def index
    @posts = Post
             .includes(:author, :comments)
             .order(created_at: :desc)

    render :index
  end

  def show
    id = params[:id]
    @post = Post
            .includes(:author, comments: [:author, :replies])
            .find_by(id:)

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
    @post = Post
            .includes(:author, comments: [:author, :replies])
            .find_by(id:)

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
    @post = Post
            .includes(:author, comments: [:author, :replies])
            .find_by(id:)

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
             .includes(:author, :comments)
             .where(author_id: params[:user_id])
             .order(created_at: :desc)

    render :index
  end

  def user_linked_posts
    @user = User.find_by(id: params[:user_id])

    if @user.present?
      render(
        json: {
          user: {
            username: @user.username,
            display_name: @user.display_name
          },
          posts: @user.linked_posts(current_user:)
        },
        status: :ok
      )
    else
      render(
        json: {errors: ["Unable to find user."]},
        status: :not_found
      )
    end
  end

  def front_page
    render(
      json: {posts: Post.popular_posts_and_comments(current_user:)},
      status: :ok
    )
  end

  def front_page_following
    render(
      json: {posts: current_user.followed_posts_and_comments},
      status: :ok
    )
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
