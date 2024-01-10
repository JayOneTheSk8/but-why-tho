require "rails_helper"

RSpec.describe "Post Requests" do
  describe "GET /posts" do
    before { create_list(:post, 7) }

    it "shows every post by latest created at date" do
      get "/posts"

      expect(response.parsed_body).to all include(:id, :text, :created_at, :author, :comment_count)
      expect(response.parsed_body.length).to eq 7
      expect(response.parsed_body)
        .to eq(response.parsed_body.sort_by { |post| Time.zone.parse(post[:created_at]) }.reverse!)
    end

    context "with comments" do
      let(:post) { Post.order("RANDOM()").take }

      before do
        comment1 = create(:comment, post:)
        create(:comment, post:)

        create(:comment, :reply, post:, comment: comment1)
        create(:comment, :reply, post:, comment: comment1)
      end

      it "shows the count of parent comments on the posts" do
        get "/posts"

        expect(response.parsed_body).to be_present
        post_res = response.parsed_body.find { |res| res[:id] == post.id }

        expect(post_res).to eq(
          {
            "id" => post.id,
            "text" => post.text,
            "comment_count" => 2,
            "created_at" => post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => post.author_id,
              "username" => post.author.username,
              "display_name" => post.author.display_name
            }
          }
        )
      end
    end

    context "when there are no posts" do
      before { Post.destroy_all }

      it "returns an empty array" do
        get "/posts"
        expect(response.parsed_body).to eq []
      end
    end
  end

  describe "GET /posts/:id" do
    let!(:post) { create(:post) }

    it "retrieves the post at the given ID" do
      get "/posts/#{post.id}"
      expect(response.parsed_body)
        .to eq(
          {
            "id" => post.id,
            "text" => post.text,
            "created_at" => post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "comment_count" => 0,
            "author" => {
              "id" => post.author_id,
              "username" => post.author.username,
              "display_name" => post.author.display_name
            },
            "comments" => []
          }
        )
    end

    context "with comments" do
      let!(:comment1) { create(:comment, post:) }
      let!(:comment2) { create(:comment, post:) }

      before do
        create(:comment, :reply, post:, comment: comment1)
        create(:comment, :reply, post:, comment: comment1)
      end

      it "includes the comments for the post" do
        get "/posts/#{post.id}"
        expect(response.parsed_body)
          .to eq(
            {
              "id" => post.id,
              "text" => post.text,
              "comment_count" => 2,
              "created_at" => post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "author" => {
                "id" => post.author_id,
                "username" => post.author.username,
                "display_name" => post.author.display_name
              },
              "comments" => [
                {
                  "id" => comment2.id,
                  "text" => comment2.text,
                  "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 0,
                  "author" => {
                    "id" => comment2.author_id,
                    "username" => comment2.author.username,
                    "display_name" => comment2.author.display_name
                  }
                },
                {
                  "id" => comment1.id,
                  "text" => comment1.text,
                  "created_at" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 2,
                  "author" => {
                    "id" => comment1.author_id,
                    "username" => comment1.author.username,
                    "display_name" => comment1.author.display_name
                  }
                }
              ]
            }
          )
      end
    end

    context "when post does not exist at given ID" do
      it "returns a not_found error" do
        get "/posts/0"
        expect(response.parsed_body).to eq "errors" => ["Unable to find Post at given ID: 0"]
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "POST /posts" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }

    let(:post_params) do
      {
        post: {
          text: Faker::Lorem.question
        }
      }
    end

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a post" do
        expect { post "/posts", params: post_params }
          .to change { Post.count }.by(1)

        post = Post.last
        expect(post).to have_attributes(
          text: post_params[:post][:text],
          author_id: user.id
        )

        expect(response.parsed_body).to eq(
          {
            "id" => post.id,
            "text" => post.text,
            "comment_count" => 0,
            "created_at" => post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => post.author_id,
              "username" => post.author.username,
              "display_name" => post.author.display_name
            },
            "comments" => []
          }
        )
      end

      context "with an invalid post" do
        it "returns an unprocessable_entity error" do
          expect { post "/posts", params: post_params.deep_merge(post: {text: Faker::Lorem.sentence}) }
            .not_to change { Post.count }

          expect(response.parsed_body).to eq "errors" => ["Text must only have questions"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "without a logged in user" do
      it "returns an unauthorized error" do
        expect { post "/posts", params: post_params }
          .not_to change { Post.count }

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage posts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "PUT /posts/:id" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let(:post_text) { Faker::Lorem.question }
    let!(:user_post) { create(:post, author_id: user.id, text: post_text) }

    let(:post_params) do
      {
        post: {
          text: Faker::Lorem.question
        }
      }
    end

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "updates the post at the given ID" do
        expect { put "/posts/#{user_post.id}", params: post_params }
          .to change { user_post.reload.text }.from(post_text).to(post_params[:post][:text])
          .and not_change { Post.count }

        expect(response.parsed_body).to eq(
          {
            "id" => user_post.id,
            "text" => post_params[:post][:text],
            "comment_count" => 0,
            "created_at" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user_post.author_id,
              "username" => user_post.author.username,
              "display_name" => user_post.author.display_name
            },
            "comments" => []
          }
        )
      end

      context "with comments" do
        let!(:comment1) { create(:comment, post: user_post) }
        let!(:comment2) { create(:comment, post: user_post) }

        before do
          create(:comment, :reply, post: user_post, comment: comment1)
          create(:comment, :reply, post: user_post, comment: comment1)
        end

        it "includes the comments for the post" do
          expect { put "/posts/#{user_post.id}", params: post_params }
            .to change { user_post.reload.text }.from(post_text).to(post_params[:post][:text])
            .and not_change { Post.count }

          expect(response.parsed_body)
            .to eq(
              {
                "id" => user_post.id,
                "text" => post_params[:post][:text],
                "comment_count" => 2,
                "created_at" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "author" => {
                  "id" => user_post.author_id,
                  "username" => user_post.author.username,
                  "display_name" => user_post.author.display_name
                },
                "comments" => [
                  {
                    "id" => comment2.id,
                    "text" => comment2.text,
                    "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                    "reply_count" => 0,
                    "author" => {
                      "id" => comment2.author_id,
                      "username" => comment2.author.username,
                      "display_name" => comment2.author.display_name
                    }
                  },
                  {
                    "id" => comment1.id,
                    "text" => comment1.text,
                    "created_at" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                    "reply_count" => 2,
                    "author" => {
                      "id" => comment1.author_id,
                      "username" => comment1.author.username,
                      "display_name" => comment1.author.display_name
                    }
                  }
                ]
              }
            )
        end
      end

      context "when post does not exist at given ID" do
        it "returns a not_found error" do
          expect { put "/posts/0", params: post_params }
            .to not_change { user_post.reload.text }
            .and not_change { Post.count }

          expect(response.parsed_body).to eq "errors" => ["Unable to find Post at given ID: 0"]
          expect(response).to have_http_status :not_found
        end
      end

      context "when author of post is different from current user" do
        let(:password) { "P@ssword1" }
        let!(:user2) { create(:user, password:) }

        before do
          get "/sign_out"
          post "/sign_in", params: {user: {login: user2.username, password:}}
        end

        it "returns an unauthorized error" do
          expect { put "/posts/#{user_post.id}", params: post_params }
            .to not_change { user_post.reload.text }
            .and not_change { Post.count }

          expect(response.parsed_body).to eq "errors" => ["Cannot update other's posts."]
          expect(response).to have_http_status :unauthorized
        end
      end

      context "with an invalid post" do
        it "returns an unprocessable_entity error" do
          expect { put "/posts/#{user_post.id}", params: post_params.deep_merge(post: {text: Faker::Lorem.sentence}) }
            .to not_change { user_post.reload.text }
            .and not_change { Post.count }

          expect(response.parsed_body).to eq "errors" => ["Text must only have questions"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "without a logged in user" do
      it "returns an unauthorized error" do
        expect { put "/posts/#{user_post.id}", params: post_params }
          .to not_change { user_post.reload.text }
          .and not_change { Post.count }

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage posts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /posts/:id" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let(:post_text) { Faker::Lorem.question }
    let!(:user_post) { create(:post, author_id: user.id, text: post_text) }

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes the post at the given ID" do
        expect { delete "/posts/#{user_post.id}" }
          .to change { Post.count }.by(-1)
          .and change { Post.find_by(id: user_post.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "id" => user_post.id,
            "text" => user_post.text,
            "comment_count" => 0,
            "created_at" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user_post.author_id,
              "username" => user_post.author.username,
              "display_name" => user_post.author.display_name
            },
            "comments" => []
          }
        )
      end

      context "with comments" do
        before do
          comment1 = create(:comment, post: user_post)
          create(:comment, post: user_post)
          create(:comment, :reply, post: user_post, comment: comment1)
          create(:comment, :reply, post: user_post, comment: comment1)
        end

        it "does not include the comments for the post" do
          expect { delete "/posts/#{user_post.id}" }
            .to change { Post.count }.by(-1)
            .and change { Post.find_by(id: user_post.id).present? }.from(true).to(false)

          expect(response.parsed_body)
            .to eq(
              {
                "id" => user_post.id,
                "text" => user_post.text,
                "comment_count" => 0,
                "created_at" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "author" => {
                  "id" => user_post.author_id,
                  "username" => user_post.author.username,
                  "display_name" => user_post.author.display_name
                },
                "comments" => []
              }
            )
        end
      end

      context "when post does not exist at given ID" do
        it "returns a not_found error" do
          expect { delete "/posts/0" }
            .to not_change { Post.count }
            .and not_change { Post.find_by(id: user_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find Post at given ID: 0"]
          expect(response).to have_http_status :not_found
        end
      end

      context "when author of post is different from current user" do
        let(:password) { "P@ssword1" }
        let!(:user2) { create(:user, password:) }

        before do
          get "/sign_out"
          post "/sign_in", params: {user: {login: user2.username, password:}}
        end

        it "returns an unauthorized error" do
          expect { delete "/posts/#{user_post.id}" }
            .to not_change { Post.count }
            .and not_change { Post.find_by(id: user_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Cannot delete other's posts."]
          expect(response).to have_http_status :unauthorized
        end
      end

      context "when an error is raised trying to destroy post" do
        before do
          allow_any_instance_of(Post).to receive(:destroy).and_return(false)
          allow_any_instance_of(Post)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable_entity error" do
          expect { delete "/posts/#{user_post.id}" }
            .to not_change { Post.count }
            .and not_change { Post.find_by(id: user_post.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "without a logged in user" do
      it "returns an unauthorized error" do
        expect { delete "/posts/#{user_post.id}" }
          .to not_change { Post.count }
          .and not_change { Post.find_by(id: user_post.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage posts."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "GET /users/:user_id/posts" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:post1) { create(:post, author_id: user.id) }
    let!(:post2) { create(:post, author_id: user.id) }
    let!(:post3) { create(:post, author_id: user.id) }

    before { create_list(:post, 5) }

    it "gets the user's posts by latest created at date" do
      get "/users/#{user.id}/posts"

      expect(response.parsed_body).to eq(
        [
          {
            "id" => post3.id,
            "text" => post3.text,
            "comment_count" => 0,
            "created_at" => post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user.id,
              "username" => user.username,
              "display_name" => user.display_name
            }
          },
          {
            "id" => post2.id,
            "text" => post2.text,
            "comment_count" => 0,
            "created_at" => post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user.id,
              "username" => user.username,
              "display_name" => user.display_name
            }
          },
          {
            "id" => post1.id,
            "text" => post1.text,
            "comment_count" => 0,
            "created_at" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user.id,
              "username" => user.username,
              "display_name" => user.display_name
            }
          }
        ]
      )
    end

    context "with comments" do
      before do
        comment1 = create(:comment, post: post2)
        create(:comment, post: post2)

        create(:comment, :reply, post: post2, comment: comment1)
        create(:comment, :reply, post: post2, comment: comment1)
      end

      it "shows the count of parent comments on the posts" do
        get "/posts"

        expect(response.parsed_body).to be_present
        post_res = response.parsed_body.find { |res| res[:id] == post2.id }

        expect(post_res).to eq(
          {
            "id" => post2.id,
            "text" => post2.text,
            "comment_count" => 2,
            "created_at" => post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => post2.author_id,
              "username" => post2.author.username,
              "display_name" => post2.author.display_name
            }
          }
        )
      end
    end

    context "when User does not exist at given ID" do
      it "returns an empty array" do
        get "/users/0/posts"
        expect(response.parsed_body).to eq []
      end
    end
  end

  describe "GET /users/:user_id/linked_posts" do
    context "when user exists" do
      let(:password) { "P0s+erk1d" }
      let!(:user) { create(:user, password:) }

      let(:user_post_like_count) { 5 }
      let(:user_post_repost_count) { 2 }
      let(:user_post_comment_count) { 4 }

      let(:reposted_post_like_count) { 3 }
      let(:reposted_post_repost_count) { 1 }
      let(:reposted_post_comment_count) { 7 }

      let(:reposted_comment_like_count) { 6 }
      let(:reposted_comment_repost_count) { 7 }
      let(:reposted_comment_comment_count) { 2 }

      let(:reposted_reply_like_count) { 9 }
      let(:reposted_reply_repost_count) { 4 }
      let(:reposted_reply_comment_count) { 1 }

      let!(:reposted_post) do
        create(
          :post,
          :liked,
          :reposted,
          :commented_with_replies,
          like_count: reposted_post_like_count,
          repost_count: reposted_post_repost_count,
          replied_comment_count: reposted_post_comment_count
        )
      end
      let!(:reposted_post_repost) { create(:post_repost, user:, message_id: reposted_post.id) }

      let!(:reposted_comment) do
        create(
          :comment,
          :liked,
          :reposted,
          :replied,
          like_count: reposted_comment_like_count,
          repost_count: reposted_comment_repost_count,
          reply_count: reposted_comment_comment_count
        )
      end
      let!(:reposted_reply) do
        create(
          :comment,
          :liked,
          :reposted,
          :reply,
          :replied,
          like_count: reposted_reply_like_count,
          repost_count: reposted_reply_repost_count,
          reply_count: reposted_reply_comment_count
        )
      end
      let!(:user_post) do
        create(
          :post,
          :liked,
          :reposted,
          :commented,
          author_id: user.id,
          like_count: user_post_like_count,
          repost_count: user_post_repost_count,
          comment_count: user_post_comment_count
        )
      end
      let!(:reposted_comment_repost) { create(:comment_repost, user:, message_id: reposted_comment.id) }
      let!(:reposted_reply_repost) { create(:comment_repost, user:, message_id: reposted_reply.id) }

      before do
        create_list(:post, 4, :liked, :commented, :reposted)
        create_list(:comment, 4, :liked, :replied, :reposted)
        create_list(:comment, 4, :reply, :liked, :replied, :reposted)
      end

      it "returns their posts and reposted posts/comments" do
        get "/users/#{user.id}/linked_posts"
        expect(response.parsed_body).to eq(
          {
            "posts" => [
              {
                "id" => reposted_reply.id,
                "text" => reposted_reply.text,
                "created_at" => reposted_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "CommentRepost",
                "like_count" => reposted_reply_like_count,
                "repost_count" => reposted_reply_repost_count + 1,
                "comment_count" => reposted_reply_comment_count,
                "post_date" => reposted_reply_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "replying_to" => [reposted_reply.parent.author.username, reposted_reply.post.author.username],
                "author" => {
                  "id" => reposted_reply.author_id,
                  "username" => reposted_reply.author.username,
                  "display_name" => reposted_reply.author.display_name
                }
              },
              {
                "id" => reposted_comment.id,
                "text" => reposted_comment.text,
                "created_at" => reposted_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "CommentRepost",
                "like_count" => reposted_comment_like_count,
                "repost_count" => reposted_comment_repost_count + 1,
                "comment_count" => reposted_comment_comment_count,
                "post_date" => reposted_comment_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "replying_to" => [reposted_comment.post.author.username],
                "author" => {
                  "id" => reposted_comment.author_id,
                  "username" => reposted_comment.author.username,
                  "display_name" => reposted_comment.author.display_name
                }
              },
              {
                "id" => user_post.id,
                "text" => user_post.text,
                "created_at" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => user_post_like_count,
                "repost_count" => user_post_repost_count,
                "comment_count" => user_post_comment_count,
                "post_date" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "replying_to" => nil,
                "author" => {
                  "id" => user_post.author_id,
                  "username" => user_post.author.username,
                  "display_name" => user_post.author.display_name
                }
              },
              {
                "id" => reposted_post.id,
                "text" => reposted_post.text,
                "created_at" => reposted_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "PostRepost",
                "like_count" => reposted_post_like_count,
                "repost_count" => reposted_post_repost_count + 1,
                "comment_count" => reposted_post_comment_count,
                "post_date" => reposted_post_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "replying_to" => nil,
                "author" => {
                  "id" => reposted_post.author_id,
                  "username" => reposted_post.author.username,
                  "display_name" => reposted_post.author.display_name
                }
              }
            ]
          }
        )
      end

      context "when user is logged in" do
        let(:current_user_password) { "N3wCUrr3n+U5er" }
        let!(:current_user) { create(:user, password: current_user_password) }

        before do
          create(:post_like, user: current_user, message_id: user_post.id)
          create(:comment_like, user: current_user, message_id: reposted_reply.id)
          create(:comment_repost, user: current_user, message_id: reposted_comment.id)
          create(:post_repost, user: current_user, message_id: reposted_post.id)
          create(:follow, follower: current_user, followee: reposted_reply.author)
          create(:follow, follower: current_user, followee: reposted_post.author)

          post("/sign_in", params: {user: {login: current_user.username, password: current_user_password}})
        end

        it "returns whether or not the logged in user liked or reposted the post/comment or followed the author" do
          get "/users/#{user.id}/linked_posts"
          expect(response.parsed_body).to eq(
            {
              "posts" => [
                {
                  "id" => reposted_reply.id,
                  "text" => reposted_reply.text,
                  "created_at" => reposted_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => reposted_reply_like_count + 1,
                  "repost_count" => reposted_reply_repost_count + 1,
                  "comment_count" => reposted_reply_comment_count,
                  "post_date" => reposted_reply_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => true,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "replying_to" => [reposted_reply.parent.author.username, reposted_reply.post.author.username],
                  "author" => {
                    "id" => reposted_reply.author_id,
                    "username" => reposted_reply.author.username,
                    "display_name" => reposted_reply.author.display_name
                  }
                },
                {
                  "id" => reposted_comment.id,
                  "text" => reposted_comment.text,
                  "created_at" => reposted_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => reposted_comment_like_count,
                  "repost_count" => reposted_comment_repost_count + 1 + 1,
                  "comment_count" => reposted_comment_comment_count,
                  "post_date" => reposted_comment_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => false,
                  "replying_to" => [reposted_comment.post.author.username],
                  "author" => {
                    "id" => reposted_comment.author_id,
                    "username" => reposted_comment.author.username,
                    "display_name" => reposted_comment.author.display_name
                  }
                },
                {
                  "id" => user_post.id,
                  "text" => user_post.text,
                  "created_at" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => user_post_like_count + 1,
                  "repost_count" => user_post_repost_count,
                  "comment_count" => user_post_comment_count,
                  "post_date" => user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => true,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "replying_to" => nil,
                  "author" => {
                    "id" => user_post.author_id,
                    "username" => user_post.author.username,
                    "display_name" => user_post.author.display_name
                  }
                },
                {
                  "id" => reposted_post.id,
                  "text" => reposted_post.text,
                  "created_at" => reposted_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "PostRepost",
                  "like_count" => reposted_post_like_count,
                  "repost_count" => reposted_post_repost_count + 1 + 1,
                  "comment_count" => reposted_post_comment_count,
                  "post_date" => reposted_post_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => true,
                  "replying_to" => nil,
                  "author" => {
                    "id" => reposted_post.author_id,
                    "username" => reposted_post.author.username,
                    "display_name" => reposted_post.author.display_name
                  }
                }
              ]
            }
          )
        end
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
