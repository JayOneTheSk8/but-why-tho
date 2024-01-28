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
    let!(:po) { create(:post) }

    it "retrieves the post at the given ID" do
      get "/posts/#{po.id}"
      expect(response.parsed_body)
        .to eq(
          {
            "id" => po.id,
            "text" => po.text,
            "created_at" => po.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "comment_count" => 0,
            "current_user_following" => false,
            "author" => {
              "id" => po.author_id,
              "username" => po.author.username,
              "display_name" => po.author.display_name
            },
            "comments" => []
          }
        )
    end

    context "when the current user is following the post author" do
      let!(:current_user) { create(:user) }

      before do
        create(:follow, follower: current_user, followee: po.author)
        post("/sign_in", params: {user: {login: current_user.username, password: current_user.password}})
      end

      it "notates the user is following them" do
        get "/posts/#{po.id}"
        expect(response.parsed_body)
          .to eq(
            {
              "id" => po.id,
              "text" => po.text,
              "created_at" => po.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 0,
              "current_user_following" => true,
              "author" => {
                "id" => po.author_id,
                "username" => po.author.username,
                "display_name" => po.author.display_name
              },
              "comments" => []
            }
          )
      end
    end

    context "with comments" do
      let!(:comment1) { create(:comment, post: po) }
      let!(:comment2) { create(:comment, post: po) }

      before do
        create(:comment, :reply, post: po, comment: comment1)
        create(:comment, :reply, post: po, comment: comment1)
      end

      it "includes the comments for the post" do
        get "/posts/#{po.id}"
        expect(response.parsed_body)
          .to eq(
            {
              "id" => po.id,
              "text" => po.text,
              "comment_count" => 2,
              "current_user_following" => false,
              "created_at" => po.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "author" => {
                "id" => po.author_id,
                "username" => po.author.username,
                "display_name" => po.author.display_name
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
            "current_user_following" => false,
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
            "current_user_following" => false,
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
                "current_user_following" => false,
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
            "current_user_following" => false,
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
                "current_user_following" => false,
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
            "user" => {
              "username" => user.username,
              "display_name" => user.display_name
            },
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
                "reposted_by" => user.display_name,
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
                "reposted_by" => user.display_name,
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
                "reposted_by" => nil,
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
                "reposted_by" => user.display_name,
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
              "user" => {
                "username" => user.username,
                "display_name" => user.display_name
              },
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
                  "reposted_by" => user.display_name,
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
                  "reposted_by" => user.display_name,
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
                  "reposted_by" => nil,
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
                  "reposted_by" => user.display_name,
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

  describe "front pages" do
    # rubocop:disable Rails/DurationArithmetic, Rails/SkipsModelValidations
    let(:todays_post1_comment_count) { 4 }
    let(:todays_post1_like_count) { 6 }
    let(:todays_post1_repost_count) { 5 }

    let(:todays_post2_comment_count) { 2 }
    let(:todays_post2_like_count) { 2 }
    let(:todays_post2_repost_count) { 6 }

    let(:todays_post3_comment_count) { 1 }
    let(:todays_post3_like_count) { 7 }
    let(:todays_post3_repost_count) { 8 }

    let(:todays_post4_comment_count) { 7 }
    let(:todays_post4_like_count) { 9 }
    let(:todays_post4_repost_count) { 2 }

    let(:todays_post5_comment_count) { 9 }
    let(:todays_post5_like_count) { 3 }
    let(:todays_post5_repost_count) { 1 }

    let(:todays_comment1_repost_count) { 6 }
    let(:todays_comment2_repost_count) { 5 }

    let!(:todays_post1) do
      # Rating 31
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: todays_post1_comment_count,
        like_count: todays_post1_like_count,
        repost_count: todays_post1_repost_count
      )
    end
    let!(:todays_post2) do
      # Rating 24
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: todays_post2_comment_count,
        like_count: todays_post2_like_count,
        repost_count: todays_post2_repost_count
      )
    end
    let!(:todays_post3) do
      # Rating 39
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: todays_post3_comment_count,
        like_count: todays_post3_like_count,
        repost_count: todays_post3_repost_count
      )
    end
    let!(:todays_post4) do
      # Rating 31 but more recent than todays_post1
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: todays_post4_comment_count,
        like_count: todays_post4_like_count,
        repost_count: todays_post4_repost_count
      )
    end
    let!(:todays_post5) do
      # Rating 18
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: todays_post5_comment_count,
        like_count: todays_post5_like_count,
        repost_count: todays_post5_repost_count
      )
    end

    let!(:todays_comment1) { create(:comment, :reposted, repost_count: todays_comment1_repost_count) } # Rating 18
    let!(:todays_comment2) { create(:comment, :reposted, repost_count: todays_comment2_repost_count) } # Rating 15
    let!(:todays_comment1_post) { todays_comment1.post } # Rating 1
    let!(:todays_comment2_post) { todays_comment2.post } # Rating 1

    let(:earlier_post1_comment_count) { 3 }
    let(:earlier_post1_like_count) { 2 }
    let(:earlier_post1_repost_count) { 6 }

    let(:earlier_post2_comment_count) { 4 }
    let(:earlier_post2_like_count) { 3 }
    let(:earlier_post2_repost_count) { 8 }

    let(:earlier_post3_comment_count) { 6 }
    let(:earlier_post3_like_count) { 1 }
    let(:earlier_post3_repost_count) { 2 }

    let(:earlier_post4_comment_count) { 2 }
    let(:earlier_post4_like_count) { 2 }
    let(:earlier_post4_repost_count) { 1 }

    let(:earlier_post5_comment_count) { 1 }
    let(:earlier_post5_like_count) { 4 }
    let(:earlier_post5_repost_count) { 7 }

    let(:earlier_comment1_repost_count) { 5 }

    let!(:earlier_post1) do
      # Rating 25
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: earlier_post1_comment_count,
        like_count: earlier_post1_like_count,
        repost_count: earlier_post1_repost_count,
        created_at: Time.current - 2.days
      )
    end
    let!(:earlier_post2) do
      # Rating 34
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: earlier_post2_comment_count,
        like_count: earlier_post2_like_count,
        repost_count: earlier_post2_repost_count,
        created_at: Time.current - 2.days
      )
    end
    let!(:earlier_post3) do
      # Rating 14
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: earlier_post3_comment_count,
        like_count: earlier_post3_like_count,
        repost_count: earlier_post3_repost_count,
        created_at: Time.current - 2.days
      )
    end
    let!(:earlier_post4) do
      # Rating 9
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: earlier_post4_comment_count,
        like_count: earlier_post4_like_count,
        repost_count: earlier_post4_repost_count,
        created_at: Time.current - 2.days
      )
    end
    let!(:earlier_post5) do
      # Rating 30
      create(
        :post,
        :commented,
        :liked,
        :reposted,
        comment_count: earlier_post5_comment_count,
        like_count: earlier_post5_like_count,
        repost_count: earlier_post5_repost_count,
        created_at: Time.current - 2.days
      )
    end

    let!(:earlier_comment1) do
      # Rating 15
      create(:comment, :reposted, repost_count: earlier_comment1_repost_count, created_at: Time.current - 2.days)
    end
    let!(:earlier_comment1_post) { earlier_comment1.post } # Rating 1
    let!(:post_with_irrelevant_comment1) { create(:comment, :reposted, repost_count: 4).post } # Rating 1
    let!(:post_with_irrelevant_comment2) { create(:comment, :liked, like_count: 7).post } # Rating 1

    let(:post_with_irrelevant_comment3_comment_count) { 8 }
    let!(:post_with_irrelevant_comment3) do
      # Rating 8
      create(:comment, :replied, reply_count: post_with_irrelevant_comment3_comment_count - 1).post
    end

    before do
      earlier_comment1_post.update_columns(created_at: Time.current - 2.days)
      post_with_irrelevant_comment1.update_columns(created_at: Time.current - 2.days)
      post_with_irrelevant_comment2.update_columns(created_at: Time.current - 2.days)
      post_with_irrelevant_comment3.update_columns(created_at: Time.current - 2.days)

      # Add reply for todays_post3 to validate comment counts
      create(:comment, :reply, :replied, comment: todays_post3.comments.last, post_id: todays_post3.id)
    end

    describe "GET /posts/front_page" do
      it "gets the most popular posts and highly reposted comments, sorting them by date and most popular" do
        get "/front_page"
        expect(response.parsed_body).to eq(
          {
            "posts" => [
              {
                "id" => todays_post3.id,
                "text" => todays_post3.text,
                "created_at" => todays_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => todays_post3_like_count,
                "repost_count" => todays_post3_repost_count,
                "comment_count" => todays_post3_comment_count,
                "post_date" => todays_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 39,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_post3.author_id,
                  "username" => todays_post3.author.username,
                  "display_name" => todays_post3.author.display_name
                }
              },
              {
                "id" => todays_post4.id,
                "text" => todays_post4.text,
                "created_at" => todays_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => todays_post4_like_count,
                "repost_count" => todays_post4_repost_count,
                "comment_count" => todays_post4_comment_count,
                "post_date" => todays_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 31,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_post4.author_id,
                  "username" => todays_post4.author.username,
                  "display_name" => todays_post4.author.display_name
                }
              },
              {
                "id" => todays_post1.id,
                "text" => todays_post1.text,
                "created_at" => todays_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => todays_post1_like_count,
                "repost_count" => todays_post1_repost_count,
                "comment_count" => todays_post1_comment_count,
                "post_date" => todays_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 31,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_post1.author_id,
                  "username" => todays_post1.author.username,
                  "display_name" => todays_post1.author.display_name
                }
              },
              {
                "id" => todays_post2.id,
                "text" => todays_post2.text,
                "created_at" => todays_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => todays_post2_like_count,
                "repost_count" => todays_post2_repost_count,
                "comment_count" => todays_post2_comment_count,
                "post_date" => todays_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 24,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_post2.author_id,
                  "username" => todays_post2.author.username,
                  "display_name" => todays_post2.author.display_name
                }
              },
              {
                "id" => todays_comment1.id,
                "text" => todays_comment1.text,
                "created_at" => todays_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "CommentRepost",
                "like_count" => 0,
                "repost_count" => todays_comment1_repost_count,
                "comment_count" => 0,
                "post_date" => todays_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 18,
                "replying_to" => [todays_comment1.post.author.username],
                "author" => {
                  "id" => todays_comment1.author_id,
                  "username" => todays_comment1.author.username,
                  "display_name" => todays_comment1.author.display_name
                }
              },
              {
                "id" => todays_post5.id,
                "text" => todays_post5.text,
                "created_at" => todays_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => todays_post5_like_count,
                "repost_count" => todays_post5_repost_count,
                "comment_count" => todays_post5_comment_count,
                "post_date" => todays_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 18,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_post5.author_id,
                  "username" => todays_post5.author.username,
                  "display_name" => todays_post5.author.display_name
                }
              },
              {
                "id" => todays_comment2.id,
                "text" => todays_comment2.text,
                "created_at" => todays_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "CommentRepost",
                "like_count" => 0,
                "repost_count" => todays_comment2_repost_count,
                "comment_count" => 0,
                "post_date" => todays_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 15,
                "replying_to" => [todays_comment2.post.author.username],
                "author" => {
                  "id" => todays_comment2.author_id,
                  "username" => todays_comment2.author.username,
                  "display_name" => todays_comment2.author.display_name
                }
              },
              {
                "id" => todays_comment2_post.id,
                "text" => todays_comment2_post.text,
                "created_at" => todays_comment2_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => 0,
                "repost_count" => 0,
                "comment_count" => 1,
                "post_date" => todays_comment2_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 1,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_comment2_post.author_id,
                  "username" => todays_comment2_post.author.username,
                  "display_name" => todays_comment2_post.author.display_name
                }
              },
              {
                "id" => todays_comment1_post.id,
                "text" => todays_comment1_post.text,
                "created_at" => todays_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => 0,
                "repost_count" => 0,
                "comment_count" => 1,
                "post_date" => todays_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 1,
                "replying_to" => nil,
                "author" => {
                  "id" => todays_comment1_post.author_id,
                  "username" => todays_comment1_post.author.username,
                  "display_name" => todays_comment1_post.author.display_name
                }
              },
              {
                "id" => earlier_post2.id,
                "text" => earlier_post2.text,
                "created_at" => earlier_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => earlier_post2_like_count,
                "repost_count" => earlier_post2_repost_count,
                "comment_count" => earlier_post2_comment_count,
                "post_date" => earlier_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 34,
                "replying_to" => nil,
                "author" => {
                  "id" => earlier_post2.author_id,
                  "username" => earlier_post2.author.username,
                  "display_name" => earlier_post2.author.display_name
                }
              },
              {
                "id" => earlier_post5.id,
                "text" => earlier_post5.text,
                "created_at" => earlier_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => earlier_post5_like_count,
                "repost_count" => earlier_post5_repost_count,
                "comment_count" => earlier_post5_comment_count,
                "post_date" => earlier_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 30,
                "replying_to" => nil,
                "author" => {
                  "id" => earlier_post5.author_id,
                  "username" => earlier_post5.author.username,
                  "display_name" => earlier_post5.author.display_name
                }
              },
              {
                "id" => earlier_post1.id,
                "text" => earlier_post1.text,
                "created_at" => earlier_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => earlier_post1_like_count,
                "repost_count" => earlier_post1_repost_count,
                "comment_count" => earlier_post1_comment_count,
                "post_date" => earlier_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 25,
                "replying_to" => nil,
                "author" => {
                  "id" => earlier_post1.author_id,
                  "username" => earlier_post1.author.username,
                  "display_name" => earlier_post1.author.display_name
                }
              },
              {
                "id" => earlier_comment1.id,
                "text" => earlier_comment1.text,
                "created_at" => earlier_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "CommentRepost",
                "like_count" => 0,
                "repost_count" => earlier_comment1_repost_count,
                "comment_count" => 0,
                "post_date" => earlier_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 15,
                "replying_to" => [earlier_comment1.post.author.username],
                "author" => {
                  "id" => earlier_comment1.author_id,
                  "username" => earlier_comment1.author.username,
                  "display_name" => earlier_comment1.author.display_name
                }
              },
              {
                "id" => earlier_post3.id,
                "text" => earlier_post3.text,
                "created_at" => earlier_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => earlier_post3_like_count,
                "repost_count" => earlier_post3_repost_count,
                "comment_count" => earlier_post3_comment_count,
                "post_date" => earlier_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 14,
                "replying_to" => nil,
                "author" => {
                  "id" => earlier_post3.author_id,
                  "username" => earlier_post3.author.username,
                  "display_name" => earlier_post3.author.display_name
                }
              },
              {
                "id" => earlier_post4.id,
                "text" => earlier_post4.text,
                "created_at" => earlier_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => earlier_post4_like_count,
                "repost_count" => earlier_post4_repost_count,
                "comment_count" => earlier_post4_comment_count,
                "post_date" => earlier_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 9,
                "replying_to" => nil,
                "author" => {
                  "id" => earlier_post4.author_id,
                  "username" => earlier_post4.author.username,
                  "display_name" => earlier_post4.author.display_name
                }
              },
              {
                "id" => post_with_irrelevant_comment3.id,
                "text" => post_with_irrelevant_comment3.text,
                "created_at" => post_with_irrelevant_comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => 0,
                "repost_count" => 0,
                "comment_count" => 1,
                "post_date" => post_with_irrelevant_comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 1,
                "replying_to" => nil,
                "author" => {
                  "id" => post_with_irrelevant_comment3.author_id,
                  "username" => post_with_irrelevant_comment3.author.username,
                  "display_name" => post_with_irrelevant_comment3.author.display_name
                }
              },
              {
                "id" => post_with_irrelevant_comment2.id,
                "text" => post_with_irrelevant_comment2.text,
                "created_at" => post_with_irrelevant_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => 0,
                "repost_count" => 0,
                "comment_count" => 1,
                "post_date" => post_with_irrelevant_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 1,
                "replying_to" => nil,
                "author" => {
                  "id" => post_with_irrelevant_comment2.author_id,
                  "username" => post_with_irrelevant_comment2.author.username,
                  "display_name" => post_with_irrelevant_comment2.author.display_name
                }
              },
              {
                "id" => post_with_irrelevant_comment1.id,
                "text" => post_with_irrelevant_comment1.text,
                "created_at" => post_with_irrelevant_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => 0,
                "repost_count" => 0,
                "comment_count" => 1,
                "post_date" => post_with_irrelevant_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 1,
                "replying_to" => nil,
                "author" => {
                  "id" => post_with_irrelevant_comment1.author_id,
                  "username" => post_with_irrelevant_comment1.author.username,
                  "display_name" => post_with_irrelevant_comment1.author.display_name
                }
              },
              {
                "id" => earlier_comment1_post.id,
                "text" => earlier_comment1_post.text,
                "created_at" => earlier_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Post",
                "like_count" => 0,
                "repost_count" => 0,
                "comment_count" => 1,
                "post_date" => earlier_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "rating" => 1,
                "replying_to" => nil,
                "author" => {
                  "id" => earlier_comment1_post.author_id,
                  "username" => earlier_comment1_post.author.username,
                  "display_name" => earlier_comment1_post.author.display_name
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
          create(:post_like, user: current_user, message_id: todays_post5.id)
          create(:post_like, user: current_user, message_id: earlier_post1.id)

          create(:comment_like, user: current_user, message_id: todays_comment1.id)
          create(:comment_like, user: current_user, message_id: earlier_comment1.id)

          create(:comment_repost, user: current_user, message_id: todays_comment2.id)
          create(:comment_repost, user: current_user, message_id: earlier_comment1.id)

          create(:post_repost, user: current_user, message_id: todays_post3.id)
          create(:post_repost, user: current_user, message_id: earlier_post2.id)

          create(:follow, follower: current_user, followee: todays_comment2.author)
          create(:follow, follower: current_user, followee: earlier_post1.author)
          create(:follow, follower: current_user, followee: post_with_irrelevant_comment2.author)

          post("/sign_in", params: {user: {login: current_user.username, password: current_user_password}})
        end

        it "returns whether or not the logged in user liked or reposted the post/comment or followed the author" do
          get "/front_page"
          expect(response.parsed_body).to eq(
            {
              "posts" => [
                {
                  "id" => todays_post3.id,
                  "text" => todays_post3.text,
                  "created_at" => todays_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => todays_post3_like_count,
                  "repost_count" => todays_post3_repost_count + 1,
                  "comment_count" => todays_post3_comment_count,
                  "post_date" => todays_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => false,
                  "rating" => 39 + 3,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_post3.author_id,
                    "username" => todays_post3.author.username,
                    "display_name" => todays_post3.author.display_name
                  }
                },
                {
                  "id" => todays_post4.id,
                  "text" => todays_post4.text,
                  "created_at" => todays_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => todays_post4_like_count,
                  "repost_count" => todays_post4_repost_count,
                  "comment_count" => todays_post4_comment_count,
                  "post_date" => todays_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 31,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_post4.author_id,
                    "username" => todays_post4.author.username,
                    "display_name" => todays_post4.author.display_name
                  }
                },
                {
                  "id" => todays_post1.id,
                  "text" => todays_post1.text,
                  "created_at" => todays_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => todays_post1_like_count,
                  "repost_count" => todays_post1_repost_count,
                  "comment_count" => todays_post1_comment_count,
                  "post_date" => todays_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 31,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_post1.author_id,
                    "username" => todays_post1.author.username,
                    "display_name" => todays_post1.author.display_name
                  }
                },
                {
                  "id" => todays_post2.id,
                  "text" => todays_post2.text,
                  "created_at" => todays_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => todays_post2_like_count,
                  "repost_count" => todays_post2_repost_count,
                  "comment_count" => todays_post2_comment_count,
                  "post_date" => todays_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 24,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_post2.author_id,
                    "username" => todays_post2.author.username,
                    "display_name" => todays_post2.author.display_name
                  }
                },
                {
                  "id" => todays_comment1.id,
                  "text" => todays_comment1.text,
                  "created_at" => todays_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => 1,
                  "repost_count" => todays_comment1_repost_count,
                  "comment_count" => 0,
                  "post_date" => todays_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => true,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 18 + 2,
                  "replying_to" => [todays_comment1.post.author.username],
                  "author" => {
                    "id" => todays_comment1.author_id,
                    "username" => todays_comment1.author.username,
                    "display_name" => todays_comment1.author.display_name
                  }
                },
                {
                  "id" => todays_post5.id,
                  "text" => todays_post5.text,
                  "created_at" => todays_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => todays_post5_like_count + 1,
                  "repost_count" => todays_post5_repost_count,
                  "comment_count" => todays_post5_comment_count,
                  "post_date" => todays_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => true,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 18 + 2,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_post5.author_id,
                    "username" => todays_post5.author.username,
                    "display_name" => todays_post5.author.display_name
                  }
                },
                {
                  "id" => todays_comment2.id,
                  "text" => todays_comment2.text,
                  "created_at" => todays_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => 0,
                  "repost_count" => todays_comment2_repost_count + 1,
                  "comment_count" => 0,
                  "post_date" => todays_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => true,
                  "rating" => 15 + 3,
                  "replying_to" => [todays_comment2.post.author.username],
                  "author" => {
                    "id" => todays_comment2.author_id,
                    "username" => todays_comment2.author.username,
                    "display_name" => todays_comment2.author.display_name
                  }
                },
                {
                  "id" => todays_comment2_post.id,
                  "text" => todays_comment2_post.text,
                  "created_at" => todays_comment2_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => todays_comment2_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_comment2_post.author_id,
                    "username" => todays_comment2_post.author.username,
                    "display_name" => todays_comment2_post.author.display_name
                  }
                },
                {
                  "id" => todays_comment1_post.id,
                  "text" => todays_comment1_post.text,
                  "created_at" => todays_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => todays_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => todays_comment1_post.author_id,
                    "username" => todays_comment1_post.author.username,
                    "display_name" => todays_comment1_post.author.display_name
                  }
                },
                {
                  "id" => earlier_post2.id,
                  "text" => earlier_post2.text,
                  "created_at" => earlier_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => earlier_post2_like_count,
                  "repost_count" => earlier_post2_repost_count + 1,
                  "comment_count" => earlier_post2_comment_count,
                  "post_date" => earlier_post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => false,
                  "rating" => 34 + 3,
                  "replying_to" => nil,
                  "author" => {
                    "id" => earlier_post2.author_id,
                    "username" => earlier_post2.author.username,
                    "display_name" => earlier_post2.author.display_name
                  }
                },
                {
                  "id" => earlier_post5.id,
                  "text" => earlier_post5.text,
                  "created_at" => earlier_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => earlier_post5_like_count,
                  "repost_count" => earlier_post5_repost_count,
                  "comment_count" => earlier_post5_comment_count,
                  "post_date" => earlier_post5.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 30,
                  "replying_to" => nil,
                  "author" => {
                    "id" => earlier_post5.author_id,
                    "username" => earlier_post5.author.username,
                    "display_name" => earlier_post5.author.display_name
                  }
                },
                {
                  "id" => earlier_post1.id,
                  "text" => earlier_post1.text,
                  "created_at" => earlier_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => earlier_post1_like_count + 1,
                  "repost_count" => earlier_post1_repost_count,
                  "comment_count" => earlier_post1_comment_count,
                  "post_date" => earlier_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => true,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "rating" => 25 + 2,
                  "replying_to" => nil,
                  "author" => {
                    "id" => earlier_post1.author_id,
                    "username" => earlier_post1.author.username,
                    "display_name" => earlier_post1.author.display_name
                  }
                },
                {
                  "id" => earlier_comment1.id,
                  "text" => earlier_comment1.text,
                  "created_at" => earlier_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => 1,
                  "repost_count" => earlier_comment1_repost_count + 1,
                  "comment_count" => 0,
                  "post_date" => earlier_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => true,
                  "user_reposted" => true,
                  "user_followed" => false,
                  "rating" => 15 + 2 + 3,
                  "replying_to" => [earlier_comment1.post.author.username],
                  "author" => {
                    "id" => earlier_comment1.author_id,
                    "username" => earlier_comment1.author.username,
                    "display_name" => earlier_comment1.author.display_name
                  }
                },
                {
                  "id" => earlier_post3.id,
                  "text" => earlier_post3.text,
                  "created_at" => earlier_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => earlier_post3_like_count,
                  "repost_count" => earlier_post3_repost_count,
                  "comment_count" => earlier_post3_comment_count,
                  "post_date" => earlier_post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 14,
                  "replying_to" => nil,
                  "author" => {
                    "id" => earlier_post3.author_id,
                    "username" => earlier_post3.author.username,
                    "display_name" => earlier_post3.author.display_name
                  }
                },
                {
                  "id" => earlier_post4.id,
                  "text" => earlier_post4.text,
                  "created_at" => earlier_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => earlier_post4_like_count,
                  "repost_count" => earlier_post4_repost_count,
                  "comment_count" => earlier_post4_comment_count,
                  "post_date" => earlier_post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 9,
                  "replying_to" => nil,
                  "author" => {
                    "id" => earlier_post4.author_id,
                    "username" => earlier_post4.author.username,
                    "display_name" => earlier_post4.author.display_name
                  }
                },
                {
                  "id" => post_with_irrelevant_comment3.id,
                  "text" => post_with_irrelevant_comment3.text,
                  "created_at" => post_with_irrelevant_comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => post_with_irrelevant_comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => post_with_irrelevant_comment3.author_id,
                    "username" => post_with_irrelevant_comment3.author.username,
                    "display_name" => post_with_irrelevant_comment3.author.display_name
                  }
                },
                {
                  "id" => post_with_irrelevant_comment2.id,
                  "text" => post_with_irrelevant_comment2.text,
                  "created_at" => post_with_irrelevant_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => post_with_irrelevant_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => post_with_irrelevant_comment2.author_id,
                    "username" => post_with_irrelevant_comment2.author.username,
                    "display_name" => post_with_irrelevant_comment2.author.display_name
                  }
                },
                {
                  "id" => post_with_irrelevant_comment1.id,
                  "text" => post_with_irrelevant_comment1.text,
                  "created_at" => post_with_irrelevant_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => post_with_irrelevant_comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => post_with_irrelevant_comment1.author_id,
                    "username" => post_with_irrelevant_comment1.author.username,
                    "display_name" => post_with_irrelevant_comment1.author.display_name
                  }
                },
                {
                  "id" => earlier_comment1_post.id,
                  "text" => earlier_comment1_post.text,
                  "created_at" => earlier_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => earlier_comment1_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => earlier_comment1_post.author_id,
                    "username" => earlier_comment1_post.author.username,
                    "display_name" => earlier_comment1_post.author.display_name
                  }
                }
              ]
            }
          )
        end
      end
    end

    describe "GET /front_page_following" do
      describe "when user is logged in" do
        let(:current_user_password) { "N3wCUrr3n+U5er" }
        let!(:current_user) { create(:user, password: current_user_password) }

        let(:followee1) { todays_comment2.author }
        let(:followee2) { earlier_post1.author }
        let(:followee3) { post_with_irrelevant_comment2.author }

        let(:followee1_reposted_post_comment_count) { 3 }
        let(:followee1_reposted_post_like_count) { 4 }
        let(:followee1_reposted_post_repost_count) { 5 }

        let(:followee3_reposted_comment_repost_count) { 2 }

        let(:current_user_reposted_post_comment_count) { 2 }
        let(:current_user_reposted_post_like_count) { 1 }
        let(:current_user_reposted_post_repost_count) { 6 }

        let(:current_user_reposted_comment_comment_count) { 4 }
        let(:current_user_reposted_comment_like_count) { 3 }
        let(:current_user_reposted_comment_repost_count) { 1 }

        let(:current_user_post_comment_count) { 5 }
        let(:current_user_post_like_count) { 5 }
        let(:current_user_post_repost_count) { 2 }

        let!(:followee1_reposted_post) do
          # Rating 26
          create(
            :post,
            :commented,
            :liked,
            :reposted,
            comment_count: followee1_reposted_post_comment_count,
            like_count: followee1_reposted_post_like_count,
            repost_count: followee1_reposted_post_repost_count,
            created_at: Time.current - 2.days
          )
        end
        let!(:followee1_reposted_post_repost) do
          create(
            :post_repost,
            user: followee1,
            message_id: followee1_reposted_post.id,
            created_at: Time.current - 2.days
          )
        end

        let!(:followee3_reposted_comment) do
          # Rating 6
          create(:comment, :reposted, repost_count: followee3_reposted_comment_repost_count)
        end
        let!(:followee3_reposted_comment_repost) do
          create(:comment_repost, user: followee3, message_id: followee3_reposted_comment.id)
        end

        let!(:current_user_reposted_post) do
          # Rating 22
          create(
            :post,
            :commented,
            :liked,
            :reposted,
            comment_count: current_user_reposted_post_comment_count,
            like_count: current_user_reposted_post_like_count,
            repost_count: current_user_reposted_post_repost_count
          )
        end
        let!(:current_user_reposted_post_repost) do
          create(:post_repost, user: current_user, message_id: current_user_reposted_post.id)
        end

        let!(:current_user_reposted_comment) do
          # Rating 13
          create(
            :comment,
            :liked,
            :reposted,
            :replied,
            reply_count: current_user_reposted_comment_comment_count,
            like_count: current_user_reposted_comment_like_count,
            repost_count: current_user_reposted_comment_repost_count
          ) do |comment|
            create(:comment_repost, user: current_user, message_id: comment.id)
          end
        end

        let!(:current_user_post) do
          # Rating 21
          create(
            :post,
            :commented,
            :liked,
            :reposted,
            author_id: current_user.id,
            comment_count: current_user_post_comment_count,
            like_count: current_user_post_like_count,
            repost_count: current_user_post_repost_count
          )
        end

        let!(:followee1_repost_of_current_user_reposted_comment) do
          create(:comment_repost, user: followee1, message_id: current_user_reposted_comment.id)
        end

        before do
          create(:follow, follower: current_user, followee: followee1)
          create(:follow, follower: current_user, followee: followee2)
          create(:follow, follower: current_user, followee: followee3)
          create(:follow, follower: current_user, followee: current_user_reposted_post.author)

          post("/sign_in", params: {user: {login: current_user.username, password: current_user_password}})
        end

        it "gets the user's own and followees' posts and reposted comments, sorting them by date and most popular" do
          get "/front_page_following"
          expect(response.parsed_body).to eq(
            {
              "posts" => [
                {
                  "id" => current_user_reposted_post.id,
                  "text" => current_user_reposted_post.text,
                  "created_at" => current_user_reposted_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "PostRepost",
                  "like_count" => current_user_reposted_post_like_count,
                  "repost_count" => current_user_reposted_post_repost_count + 1,
                  "comment_count" => current_user_reposted_post_comment_count,
                  "post_date" => current_user_reposted_post_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => current_user.display_name,
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => true,
                  "rating" => 22 + 3,
                  "replying_to" => nil,
                  "author" => {
                    "id" => current_user_reposted_post.author_id,
                    "username" => current_user_reposted_post.author.username,
                    "display_name" => current_user_reposted_post.author.display_name
                  }
                },
                {
                  "id" => current_user_reposted_post.id,
                  "text" => current_user_reposted_post.text,
                  "created_at" => current_user_reposted_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => current_user_reposted_post_like_count,
                  "repost_count" => current_user_reposted_post_repost_count + 1,
                  "comment_count" => current_user_reposted_post_comment_count,
                  "post_date" => current_user_reposted_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => nil,
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => true,
                  "rating" => 22 + 3,
                  "replying_to" => nil,
                  "author" => {
                    "id" => current_user_reposted_post.author_id,
                    "username" => current_user_reposted_post.author.username,
                    "display_name" => current_user_reposted_post.author.display_name
                  }
                },
                {
                  "id" => current_user_post.id,
                  "text" => current_user_post.text,
                  "created_at" => current_user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => current_user_post_like_count,
                  "repost_count" => current_user_post_repost_count,
                  "comment_count" => current_user_post_comment_count,
                  "post_date" => current_user_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => nil,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 21,
                  "replying_to" => nil,
                  "author" => {
                    "id" => current_user.id,
                    "username" => current_user.username,
                    "display_name" => current_user.display_name
                  }
                },
                {
                  "id" => current_user_reposted_comment.id,
                  "text" => current_user_reposted_comment.text,
                  "created_at" => current_user_reposted_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => current_user_reposted_comment_like_count,
                  "repost_count" => current_user_reposted_comment_repost_count + 1 + 1,
                  "comment_count" => current_user_reposted_comment_comment_count,
                  "post_date" => followee1_repost_of_current_user_reposted_comment
                                 .created_at
                                 .strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => followee1.display_name,
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => false,
                  "rating" => 13 + 3 + 3,
                  "replying_to" => [current_user_reposted_comment.post.author.username],
                  "author" => {
                    "id" => current_user_reposted_comment.author_id,
                    "username" => current_user_reposted_comment.author.username,
                    "display_name" => current_user_reposted_comment.author.display_name
                  }
                },
                {
                  "id" => followee3_reposted_comment.id,
                  "text" => followee3_reposted_comment.text,
                  "created_at" => followee3_reposted_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => 0,
                  "repost_count" => followee3_reposted_comment_repost_count + 1,
                  "comment_count" => 0,
                  "post_date" => followee3_reposted_comment_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => followee3.display_name,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 6 + 3,
                  "replying_to" => [followee3_reposted_comment.post.author.username],
                  "author" => {
                    "id" => followee3_reposted_comment.author_id,
                    "username" => followee3_reposted_comment.author.username,
                    "display_name" => followee3_reposted_comment.author.display_name
                  }
                },
                {
                  "id" => followee1_reposted_post.id,
                  "text" => followee1_reposted_post.text,
                  "created_at" => followee1_reposted_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "PostRepost",
                  "like_count" => followee1_reposted_post_like_count,
                  "repost_count" => followee1_reposted_post_repost_count + 1,
                  "comment_count" => followee1_reposted_post_comment_count,
                  "post_date" => followee1_reposted_post_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => followee1.display_name,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "rating" => 26 + 3,
                  "replying_to" => nil,
                  "author" => {
                    "id" => followee1_reposted_post.author_id,
                    "username" => followee1_reposted_post.author.username,
                    "display_name" => followee1_reposted_post.author.display_name
                  }
                },
                {
                  "id" => earlier_post1.id,
                  "text" => earlier_post1.text,
                  "created_at" => earlier_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => earlier_post1_like_count,
                  "repost_count" => earlier_post1_repost_count,
                  "comment_count" => earlier_post1_comment_count,
                  "post_date" => earlier_post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => nil,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "rating" => 25,
                  "replying_to" => nil,
                  "author" => {
                    "id" => followee2.id,
                    "username" => followee2.username,
                    "display_name" => followee2.display_name
                  }
                },
                {
                  "id" => post_with_irrelevant_comment2.id,
                  "text" => post_with_irrelevant_comment2.text,
                  "created_at" => post_with_irrelevant_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Post",
                  "like_count" => 0,
                  "repost_count" => 0,
                  "comment_count" => 1,
                  "post_date" => post_with_irrelevant_comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => nil,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "rating" => 1,
                  "replying_to" => nil,
                  "author" => {
                    "id" => followee3.id,
                    "username" => followee3.username,
                    "display_name" => followee3.display_name
                  }
                }
              ]
            }
          )
        end
      end

      context "when user is not logged in" do
        it "returns an unauthorized error" do
          get "/front_page_following"
          expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage posts."]
          expect(response).to have_http_status :unauthorized
        end
      end
    end
    # rubocop:enable Rails/DurationArithmetic, Rails/SkipsModelValidations
  end

  describe "GET /posts/:post_id/data" do
    let(:post_like_count) { 3 }
    let(:post_repost_count) { 2 }

    let(:comment1_like_count) { 2 }
    let(:comment1_repost_count) { 4 }

    let(:comment2_like_count) { 5 }
    let(:comment2_repost_count) { 3 }

    let!(:shown_post) do
      create(
        :post,
        :liked,
        :reposted,
        like_count: post_like_count,
        repost_count: post_repost_count
      )
    end
    let!(:comment1) do
      create(
        :comment,
        :liked,
        :reposted,
        :replied,
        post_id: shown_post.id,
        like_count: comment1_like_count,
        repost_count: comment1_repost_count
      )
    end
    let!(:comment2) do
      create(
        :comment,
        :liked,
        :reposted,
        post_id: shown_post.id,
        like_count: comment2_like_count,
        repost_count: comment2_repost_count
      )
    end

    context "when post exists" do
      let!(:uncommented_post) { create(:post, :liked, :reposted) }

      it "returns the post's data" do
        get "/posts/#{uncommented_post.id}/data"
        expect(response.parsed_body).to eq(
          "post" => {
            "id" => uncommented_post.id,
            "text" => uncommented_post.text,
            "created_at" => uncommented_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "comment_count" => 0,
            "like_count" => 1,
            "repost_count" => 1,
            "user_liked" => false,
            "user_reposted" => false,
            "user_followed" => false,
            "replying_to" => nil,
            "author" => {
              "id" => uncommented_post.author_id,
              "username" => uncommented_post.author.username,
              "display_name" => uncommented_post.author.display_name
            },
            "comments" => []
          }
        )
      end

      context "with comments" do
        it "returns the post's top-level comments" do
          get "/posts/#{shown_post.id}/data"
          expect(response.parsed_body).to eq(
            "post" => {
              "id" => shown_post.id,
              "text" => shown_post.text,
              "created_at" => shown_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 2,
              "like_count" => post_like_count,
              "repost_count" => post_repost_count,
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "replying_to" => nil,
              "author" => {
                "id" => shown_post.author_id,
                "username" => shown_post.author.username,
                "display_name" => shown_post.author.display_name
              },
              "comments" => [
                {
                  "id" => comment2.id,
                  "text" => comment2.text,
                  "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "comment_count" => 0,
                  "like_count" => comment2_like_count,
                  "repost_count" => comment2_repost_count,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "replying_to" => [shown_post.author.username],
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
                  "comment_count" => 1,
                  "like_count" => comment1_like_count,
                  "repost_count" => comment1_repost_count,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => false,
                  "replying_to" => [shown_post.author.username],
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

      context "when user is logged in" do
        let!(:user) { create(:user) }

        before do
          create(:follow, follower: user, followee: comment1.author)
          create(:follow, follower: user, followee: shown_post.author)

          create(:comment_like, user:, message_id: comment2.id)

          create(:comment_repost, user:, message_id: comment2.id)
          create(:post_repost, user:, message_id: shown_post.id)

          post("/sign_in", params: {user: {login: user.username, password: user.password}})
        end

        it "notates whether the current user liked or reposted the message or followed the author" do
          get "/posts/#{shown_post.id}/data"
          expect(response.parsed_body).to eq(
            "post" => {
              "id" => shown_post.id,
              "text" => shown_post.text,
              "created_at" => shown_post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 2,
              "like_count" => post_like_count,
              "repost_count" => post_repost_count + 1,
              "user_liked" => false,
              "user_reposted" => true,
              "user_followed" => true,
              "replying_to" => nil,
              "author" => {
                "id" => shown_post.author_id,
                "username" => shown_post.author.username,
                "display_name" => shown_post.author.display_name
              },
              "comments" => [
                {
                  "id" => comment2.id,
                  "text" => comment2.text,
                  "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "comment_count" => 0,
                  "like_count" => comment2_like_count + 1,
                  "repost_count" => comment2_repost_count + 1,
                  "user_liked" => true,
                  "user_reposted" => true,
                  "user_followed" => false,
                  "replying_to" => [shown_post.author.username],
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
                  "comment_count" => 1,
                  "like_count" => comment1_like_count,
                  "repost_count" => comment1_repost_count,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "replying_to" => [shown_post.author.username],
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
    end

    context "when post does not exist" do
      it "returns a not found error" do
        get "/posts/0/data"
        expect(response.parsed_body).to eq "errors" => ["Unable to find Post at given ID: 0"]
        expect(response).to have_http_status :not_found
      end
    end
  end
end
