class CommentsController < ApplicationController
  before_action :require_login, only: [:create, :update, :destroy]

  def show
    id = params[:id]
    @comment = Comment
               .joins(:author, :post) # Reduce SQL queries to 2
               .left_outer_joins(:parent, :replies)
               .includes(
                 :author,
                 parent: [:author, :replies],
                 post: [:author, :comments],
                 replies: [:author, :replies]
               )
               .find_by(id:)

    if @comment.present?
      render :show
    else
      render(
        json: {errors: [not_found_comment_error_message(id)]},
        status: :not_found
      )
    end
  end

  def create
    @comment = Comment.new(create_comment_params)
    @comment.author_id = current_user.id

    if @comment.save
      render :show
    else
      render(
        json: {errors: @comment.errors.full_messages},
        status: :unprocessable_entity
      )
    end
  end

  def update
    id = params[:id]
    @comment = Comment
               .joins(:author, :post)
               .left_outer_joins(:parent, :replies)
               .includes(
                 :author,
                 parent: [:author, :replies],
                 post: [:author, :comments],
                 replies: [:author, :replies]
               )
               .find_by(id:)

    if @comment.present?
      if @comment.author_id == current_user.id
        if @comment.update(update_comment_params)
          render :show
        else
          render(
            json: {errors: @comment.errors.full_messages},
            status: :unprocessable_entity
          )
        end
      else
        render(
          json: {errors: ["Cannot update other's comments."]},
          status: :unauthorized
        )
      end
    else
      render(
        json: {errors: [not_found_comment_error_message(id)]},
        status: :not_found
      )
    end
  end

  def destroy
    id = params[:id]
    @comment = Comment
               .joins(:author, :post)
               .left_outer_joins(:parent, :replies)
               .includes(
                 :author,
                 parent: [:author, :replies],
                 post: [:author, :comments],
                 replies: [:author, :replies]
               )
               .find_by(id:)

    if @comment.present?
      if @comment.author_id == current_user.id
        if @comment.destroy
          render :show
        else
          render(
            json: {errors: @comment.errors.full_messages},
            status: :unprocessable_entity
          )
        end
      else
        render(
          json: {errors: ["Cannot delete other's comments."]},
          status: :unauthorized
        )
      end
    else
      render(
        json: {errors: [not_found_comment_error_message(id)]},
        status: :not_found
      )
    end
  end

  def user_comments
    @comments = Comment
                .joins(:author, :post)
                .left_outer_joins(:parent, :replies)
                .includes(
                  :author,
                  parent: [:author, :replies],
                  post: [:author, :comments],
                  replies: [:author, :replies]
                )
                .where(author_id: params[:user_id])
                .order(created_at: :desc)

    render "comments/user_comments"
  end

  private

  def require_login
    return if logged_in?

    render(
      json: {errors: ["Must be logged in to manage comments."]},
      status: :unauthorized
    )
  end

  def create_comment_params
    params.require(:comment).permit(:text, :post_id, :parent_id)
  end

  def update_comment_params
    params.require(:comment).permit(:text)
  end

  def not_found_comment_error_message(id)
    "Unable to find Comment at given ID: #{id}"
  end
end