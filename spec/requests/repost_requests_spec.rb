require "rails_helper"

RSpec.describe "Repost Requests" do
  describe "POST /comment_reposts" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment) { create(:comment) }

    let(:repost_params) do
      {
        repost: {
          message_id: comment.id
        }
      }
    end

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a comment repost for the user" do
        expect { post "/comment_reposts", params: repost_params }
          .to change { CommentRepost.count }.by(1)
          .and change { CommentRepost.find_by(user_id: user.id, message_id: comment.id).present? }.from(false).to(true)

        expect(response.parsed_body).to eq(
          {
            "type" => "CommentRepost",
            "comment_id" => comment.id,
            "user_id" => user.id
          }
        )
      end

      context "when comment repost could not be saved" do
        it "returns an unprocessable entity error" do
          expect { post "/comment_reposts", params: {repost: {message_id: 0}} }
            .not_to change { CommentRepost.count }

          expect(response.parsed_body).to eq "errors" => ["Comment must exist"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        post "/comment_reposts", params: repost_params
        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage reposts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "POST /post_reposts" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:post_to_repost) { create(:post) }

    let(:repost_params) do
      {
        repost: {
          message_id: post_to_repost.id
        }
      }
    end

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a post repost for the user" do
        expect { post "/post_reposts", params: repost_params }
          .to change { PostRepost.count }.by(1)
          .and change { PostRepost.find_by(user_id: user.id, message_id: post_to_repost.id).present? }.from(false).to(true)

        expect(response.parsed_body).to eq(
          {
            "type" => "PostRepost",
            "post_id" => post_to_repost.id,
            "user_id" => user.id
          }
        )
      end

      context "when post repost could not be saved" do
        it "returns an unprocessable entity error" do
          expect { post "/post_reposts", params: {repost: {message_id: 0}} }
            .not_to change { PostRepost.count }

          expect(response.parsed_body).to eq "errors" => ["Post must exist"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        post "/post_reposts", params: repost_params
        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage reposts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /comment_reposts" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment) { create(:comment) }

    let(:repost_params) do
      {
        repost: {
          message_id: comment.id
        }
      }
    end

    before { create(:comment_repost, message_id: comment.id, user:) }

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes a comment repost" do
        expect { delete "/comment_reposts", params: repost_params }
          .to change { CommentRepost.count }.by(-1)
          .and change { CommentRepost.find_by(user_id: user.id, message_id: comment.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "type" => "CommentRepost",
            "comment_id" => comment.id,
            "user_id" => user.id
          }
        )
      end

      context "when comment repost does not exist" do
        it "returns a not found error" do
          expect { delete "/comment_reposts", params: {repost: {message_id: 0}} }
            .to not_change { CommentRepost.count }
            .and not_change { CommentRepost.find_by(user_id: user.id, message_id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find repost reference."]
          expect(response).to have_http_status :not_found
        end
      end

      context "when comment repost could not be destroyed" do
        before do
          allow_any_instance_of(CommentRepost).to receive(:destroy).and_return(false)
          allow_any_instance_of(CommentRepost)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable entity error" do
          expect { delete "/comment_reposts", params: repost_params }
            .to not_change { CommentRepost.count }
            .and not_change { CommentRepost.find_by(user_id: user.id, message_id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        expect { delete "/comment_reposts", params: repost_params }
          .to not_change { CommentRepost.count }
          .and not_change { CommentRepost.find_by(user_id: user.id, message_id: comment.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage reposts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /post_reposts" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:reposted_post) { create(:post) }

    let(:repost_params) do
      {
        repost: {
          message_id: reposted_post.id
        }
      }
    end

    before { create(:post_repost, message_id: reposted_post.id, user:) }

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes a post repost" do
        expect { delete "/post_reposts", params: repost_params }
          .to change { PostRepost.count }.by(-1)
          .and change { PostRepost.find_by(user_id: user.id, message_id: reposted_post.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "type" => "PostRepost",
            "post_id" => reposted_post.id,
            "user_id" => user.id
          }
        )
      end

      context "when post repost does not exist" do
        it "returns a not found error" do
          expect { delete "/post_reposts", params: {repost: {message_id: 0}} }
            .to not_change { PostRepost.count }
            .and not_change { PostRepost.find_by(user_id: user.id, message_id: reposted_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find repost reference."]
          expect(response).to have_http_status :not_found
        end
      end

      context "when post repost could not be destroyed" do
        before do
          allow_any_instance_of(PostRepost).to receive(:destroy).and_return(false)
          allow_any_instance_of(PostRepost)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable entity error" do
          expect { delete "/post_reposts", params: repost_params }
            .to not_change { PostRepost.count }
            .and not_change { PostRepost.find_by(user_id: user.id, message_id: reposted_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        expect { delete "/post_reposts", params: repost_params }
          .to not_change { PostRepost.count }
          .and not_change { PostRepost.find_by(user_id: user.id, message_id: reposted_post.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage reposts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end
end
