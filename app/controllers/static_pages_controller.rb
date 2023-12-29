class StaticPagesController < ApplicationController
  def home
    @posts = Post.all
    render :root
  end
end
