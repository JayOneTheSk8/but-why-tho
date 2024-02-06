class SearchController < ApplicationController
  def quick
    render(
      json: {
        users: User.search_users(search_text, current_user:, limit: 6)
      },
      status: :ok
    )
  end

  def top
    render(
      json: {
        users: User.search_users(search_text, current_user:, limit: 3),
        posts: Post.search_posts(search_text, current_user:, limit: 3),
        comments: Comment.search_comments(search_text, current_user:, limit: 3)
      },
      status: :ok
    )
  end

  def users
    render(
      json: {
        users: User.search_users(search_text, current_user:)
      },
      status: :ok
    )
  end

  def posts
    render(
      json: {
        posts: Post.search_posts(search_text, current_user:)
      },
      status: :ok
    )
  end

  def comments
    render(
      json: {
        comments: Comment.search_comments(search_text, current_user:)
      },
      status: :ok
    )
  end

  private

  def search_text
    params[:search][:text]
  end
end
