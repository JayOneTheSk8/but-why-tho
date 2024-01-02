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
              "username" => post.author.username
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
              "username" => post.author.username
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
                "username" => post.author.username
              },
              "comments" => [
                {
                  "id" => comment2.id,
                  "text" => comment2.text,
                  "reply_count" => 0,
                  "author" => {
                    "id" => comment2.author_id,
                    "username" => comment2.author.username
                  }
                },
                {
                  "id" => comment1.id,
                  "text" => comment1.text,
                  "reply_count" => 2,
                  "author" => {
                    "id" => comment1.author_id,
                    "username" => comment1.author.username
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
              "username" => post.author.username
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
              "username" => user_post.author.username
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
                  "username" => user_post.author.username
                },
                "comments" => [
                  {
                    "id" => comment2.id,
                    "text" => comment2.text,
                    "reply_count" => 0,
                    "author" => {
                      "id" => comment2.author_id,
                      "username" => comment2.author.username
                    }
                  },
                  {
                    "id" => comment1.id,
                    "text" => comment1.text,
                    "reply_count" => 2,
                    "author" => {
                      "id" => comment1.author_id,
                      "username" => comment1.author.username
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
              "username" => user_post.author.username
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
                  "username" => user_post.author.username
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
              "username" => user.username
            }
          },
          {
            "id" => post2.id,
            "text" => post2.text,
            "comment_count" => 0,
            "created_at" => post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user.id,
              "username" => user.username
            }
          },
          {
            "id" => post1.id,
            "text" => post1.text,
            "comment_count" => 0,
            "created_at" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "author" => {
              "id" => user.id,
              "username" => user.username
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
              "username" => post2.author.username
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
end
