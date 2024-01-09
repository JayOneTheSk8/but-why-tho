require "rails_helper"

RSpec.describe "Like Requests" do
  describe "POST /comment_likes" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment) { create(:comment) }

    let(:like_params) do
      {
        like: {
          message_id: comment.id
        }
      }
    end

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a comment like for the user" do
        expect { post "/comment_likes", params: like_params }
          .to change { CommentLike.count }.by(1)
          .and change { CommentLike.find_by(user_id: user.id, message_id: comment.id).present? }.from(false).to(true)

        expect(response.parsed_body).to eq(
          {
            "type" => "CommentLike",
            "comment_id" => comment.id,
            "user_id" => user.id
          }
        )
      end

      context "when comment like could not be saved" do
        it "returns an unprocessable entity error" do
          expect { post "/comment_likes", params: {like: {message_id: 0}} }
            .not_to change { CommentLike.count }

          expect(response.parsed_body).to eq "errors" => ["Comment must exist"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        post "/comment_likes", params: like_params
        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage likes."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "POST /post_likes" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:post_to_like) { create(:post) }

    let(:like_params) do
      {
        like: {
          message_id: post_to_like.id
        }
      }
    end

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a post like for the user" do
        expect { post "/post_likes", params: like_params }
          .to change { PostLike.count }.by(1)
          .and change { PostLike.find_by(user_id: user.id, message_id: post_to_like.id).present? }.from(false).to(true)

        expect(response.parsed_body).to eq(
          {
            "type" => "PostLike",
            "post_id" => post_to_like.id,
            "user_id" => user.id
          }
        )
      end

      context "when post like could not be saved" do
        it "returns an unprocessable entity error" do
          expect { post "/post_likes", params: {like: {message_id: 0}} }
            .not_to change { PostLike.count }

          expect(response.parsed_body).to eq "errors" => ["Post must exist"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        post "/post_likes", params: like_params
        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage likes."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /comment_likes" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment) { create(:comment) }

    let(:like_params) do
      {
        like: {
          message_id: comment.id
        }
      }
    end

    before { create(:comment_like, message_id: comment.id, user:) }

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes a comment like" do
        expect { delete "/comment_likes", params: like_params }
          .to change { CommentLike.count }.by(-1)
          .and change { CommentLike.find_by(user_id: user.id, message_id: comment.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "type" => "CommentLike",
            "comment_id" => comment.id,
            "user_id" => user.id
          }
        )
      end

      context "when comment like does not exist" do
        it "returns a not found error" do
          expect { delete "/comment_likes", params: {like: {message_id: 0}} }
            .to not_change { CommentLike.count }
            .and not_change { CommentLike.find_by(user_id: user.id, message_id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find like reference."]
          expect(response).to have_http_status :not_found
        end
      end

      context "when comment like could not be destroyed" do
        before do
          allow_any_instance_of(CommentLike).to receive(:destroy).and_return(false)
          allow_any_instance_of(CommentLike)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable entity error" do
          expect { delete "/comment_likes", params: like_params }
            .to not_change { CommentLike.count }
            .and not_change { CommentLike.find_by(user_id: user.id, message_id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        expect { delete "/comment_likes", params: like_params }
          .to not_change { CommentLike.count }
          .and not_change { CommentLike.find_by(user_id: user.id, message_id: comment.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage likes."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /post_likes" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:liked_post) { create(:post) }

    let(:like_params) do
      {
        like: {
          message_id: liked_post.id
        }
      }
    end

    before { create(:post_like, message_id: liked_post.id, user:) }

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes a post like" do
        expect { delete "/post_likes", params: like_params }
          .to change { PostLike.count }.by(-1)
          .and change { PostLike.find_by(user_id: user.id, message_id: liked_post.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "type" => "PostLike",
            "post_id" => liked_post.id,
            "user_id" => user.id
          }
        )
      end

      context "when post like does not exist" do
        it "returns a not found error" do
          expect { delete "/post_likes", params: {like: {message_id: 0}} }
            .to not_change { PostLike.count }
            .and not_change { PostLike.find_by(user_id: user.id, message_id: liked_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find like reference."]
          expect(response).to have_http_status :not_found
        end
      end

      context "when post like could not be destroyed" do
        before do
          allow_any_instance_of(PostLike).to receive(:destroy).and_return(false)
          allow_any_instance_of(PostLike)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable entity error" do
          expect { delete "/post_likes", params: like_params }
            .to not_change { PostLike.count }
            .and not_change { PostLike.find_by(user_id: user.id, message_id: liked_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        expect { delete "/post_likes", params: like_params }
          .to not_change { PostLike.count }
          .and not_change { PostLike.find_by(user_id: user.id, message_id: liked_post.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage likes."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "GET /users/:user_id/likes" do
    context "when user exists" do
      # NOTE: These are the like counts before the user likes are created so will need +1
      let(:post1_like_count) { 22 }
      let(:post2_like_count) { 15 }
      let(:comment1_like_count) { 2 }
      let(:comment2_like_count) { 30 }
      let(:reply1_like_count) { 11 }

      let(:post2_repost_count) { 3 }
      let(:comment1_repost_count) { 5 }

      let(:post1_comment_count) { 4 }
      let(:comment2_comment_count) { 2 }

      let!(:post1) do
        create(
          :post,
          :liked,
          :commented_with_replies,
          like_count: post1_like_count,
          replied_comment_count: post1_comment_count
        )
      end
      let!(:post2) do
        create(
          :post,
          :liked,
          :reposted,
          like_count: post2_like_count,
          repost_count: post2_repost_count
        )
      end

      let!(:comment1) do
        create(
          :comment,
          :liked,
          :reposted,
          like_count: comment1_like_count,
          repost_count: comment1_repost_count
        )
      end
      let!(:comment2) do
        create(
          :comment,
          :liked,
          :replied,
          like_count: comment2_like_count,
          reply_count: comment2_comment_count
        )
      end

      let!(:reply1) do
        create(
          :comment,
          :reply,
          :liked,
          like_count: reply1_like_count
        )
      end

      let(:user) { create(:user) }

      let!(:like1) { create(:post_like, user:, message_id: post2.id) }
      let!(:like2) { create(:comment_like, user:, message_id: reply1.id) }
      let!(:like3) { create(:comment_like, user:, message_id: comment1.id) }
      let!(:like4) { create(:post_like, user:, message_id: post1.id) }
      let!(:like5) { create(:comment_like, user:, message_id: comment2.id) }

      before do
        create_list(:post, 4, :liked, like_count: 5)
        create_list(:comment, 4, :liked, like_count: 5)
        create_list(:comment, 4, :reply, :liked, like_count: 5)

        create(:comment_repost, user:, message_id: comment2.id)
        create(:post_repost, user:, message_id: post2.id)
      end

      it "returns their liked posts and comments" do
        get "/users/#{user.id}/likes"
        expect(response.parsed_body).to eq(
          {
            "likes" => [
              {
                "id" => comment2.id,
                "text" => comment2.text,
                "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "like_type" => "CommentLike",
                "like_count" => comment2_like_count + 1,
                "liked_at" => like5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "repost_count" => 1, # user is the only one to repost
                "comment_count" => comment2_comment_count,
                "user_reposted" => true,
                "user_liked" => true,
                "author" => {
                  "id" => comment2.author_id,
                  "username" => comment2.author.username,
                  "display_name" => comment2.author.display_name
                }
              },
              {
                "id" => post1.id,
                "text" => post1.text,
                "created_at" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "like_type" => "PostLike",
                "like_count" => post1_like_count + 1,
                "liked_at" => like4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "repost_count" => 0,
                "comment_count" => post1_comment_count,
                "user_reposted" => false,
                "user_liked" => true,
                "author" => {
                  "id" => post1.author_id,
                  "username" => post1.author.username,
                  "display_name" => post1.author.display_name
                }
              },
              {
                "id" => comment1.id,
                "text" => comment1.text,
                "created_at" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "like_type" => "CommentLike",
                "like_count" => comment1_like_count + 1,
                "liked_at" => like3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "repost_count" => comment1_repost_count,
                "comment_count" => 0,
                "user_reposted" => false,
                "user_liked" => true,
                "author" => {
                  "id" => comment1.author_id,
                  "username" => comment1.author.username,
                  "display_name" => comment1.author.display_name
                }
              },
              {
                "id" => reply1.id,
                "text" => reply1.text,
                "created_at" => reply1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "like_type" => "CommentLike",
                "like_count" => reply1_like_count + 1,
                "liked_at" => like2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "repost_count" => 0,
                "comment_count" => 0,
                "user_reposted" => false,
                "user_liked" => true,
                "author" => {
                  "id" => reply1.author_id,
                  "username" => reply1.author.username,
                  "display_name" => reply1.author.display_name
                }
              },
              {
                "id" => post2.id,
                "text" => post2.text,
                "created_at" => post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "like_type" => "PostLike",
                "like_count" => post2_like_count + 1,
                "liked_at" => like1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "repost_count" => post2_repost_count + 1,
                "comment_count" => 0,
                "user_reposted" => true,
                "user_liked" => true,
                "author" => {
                  "id" => post2.author_id,
                  "username" => post2.author.username,
                  "display_name" => post2.author.display_name
                }
              }
            ]
          }
        )
      end
    end

    context "when user does not exist" do
      it "returns a not found error" do
        get "/users/0/likes"
        expect(response.parsed_body).to eq "errors" => ["Unable to find user."]
        expect(response).to have_http_status :not_found
      end
    end
  end
end
