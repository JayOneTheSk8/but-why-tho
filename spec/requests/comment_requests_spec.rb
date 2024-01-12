require "rails_helper"

RSpec.describe "Comment Requests" do
  describe "GET /comments/:id" do
    let!(:comment) { create(:comment) }

    it "retrieves the comment at the given ID" do
      get "/comments/#{comment.id}"
      expect(response.parsed_body)
        .to eq(
          {
            "id" => comment.id,
            "text" => comment.text,
            "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "current_user_following" => false,
            "author" => {
              "id" => comment.author_id,
              "username" => comment.author.username,
              "display_name" => comment.author.display_name
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => comment.post.comments.count,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username,
                "display_name" => comment.post.author.display_name
              }
            },
            "parent" => nil,
            "replies" => []
          }
        )
    end

    context "when current logged in user follows the comment author" do
      let!(:current_user) { create(:user) }

      before do
        create(:follow, follower: current_user, followee: comment.author)
        post "/sign_in", params: {user: {login: current_user.username, password: current_user.password}}
      end

      it "notates the user is following them" do
        get "/comments/#{comment.id}"
        expect(response.parsed_body)
          .to eq(
            {
              "id" => comment.id,
              "text" => comment.text,
              "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "reply_count" => 0,
              "current_user_following" => true,
              "author" => {
                "id" => comment.author_id,
                "username" => comment.author.username,
                "display_name" => comment.author.display_name
              },
              "post" => {
                "id" => comment.post_id,
                "text" => comment.post.text,
                "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "comment_count" => comment.post.comments.count,
                "author" => {
                  "id" => comment.post.author_id,
                  "username" => comment.post.author.username,
                  "display_name" => comment.post.author.display_name
                }
              },
              "parent" => nil,
              "replies" => []
            }
          )
      end
    end

    context "when comment has replies" do
      let!(:reply1) { create(:comment, :reply, post: comment.post, comment:) }
      let!(:reply2) { create(:comment, :reply, post: comment.post, comment:) }

      before do
        create(:comment, :reply, post: comment.post, comment: reply2)
        create(:comment, :reply, post: comment.post, comment: reply2)
      end

      it "retrieves the comment's replies" do
        get "/comments/#{comment.id}"
        expect(response.parsed_body)
          .to eq(
            {
              "id" => comment.id,
              "text" => comment.text,
              "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "reply_count" => 2,
              "current_user_following" => false,
              "author" => {
                "id" => comment.author_id,
                "username" => comment.author.username,
                "display_name" => comment.author.display_name
              },
              "post" => {
                "id" => comment.post_id,
                "text" => comment.post.text,
                "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "comment_count" => comment.post.comments.count,
                "author" => {
                  "id" => comment.post.author_id,
                  "username" => comment.post.author.username,
                  "display_name" => comment.post.author.display_name
                }
              },
              "parent" => nil,
              "replies" => [
                {
                  "id" => reply2.id,
                  "text" => reply2.text,
                  "created_at" => reply2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 2,
                  "author" => {
                    "id" => reply2.author_id,
                    "username" => reply2.author.username,
                    "display_name" => reply2.author.display_name
                  }
                },
                {
                  "id" => reply1.id,
                  "text" => reply1.text,
                  "created_at" => reply1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 0,
                  "author" => {
                    "id" => reply1.author_id,
                    "username" => reply1.author.username,
                    "display_name" => reply1.author.display_name
                  }
                }
              ]
            }
          )
      end
    end

    context "when comment is a reply" do
      let!(:parent_comment) { create(:comment, post: comment.post) }

      before do
        create(:comment, :reply, post: comment.post, comment: parent_comment)
        comment.update!(parent_id: parent_comment.id)
      end

      it "retrieves the comment's parent" do
        get "/comments/#{comment.id}"
        expect(response.parsed_body)
          .to eq(
            {
              "id" => comment.id,
              "text" => comment.text,
              "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "reply_count" => 0,
              "current_user_following" => false,
              "author" => {
                "id" => comment.author_id,
                "username" => comment.author.username,
                "display_name" => comment.author.display_name
              },
              "post" => {
                "id" => comment.post_id,
                "text" => comment.post.text,
                "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "comment_count" => comment.post.comments.count,
                "author" => {
                  "id" => comment.post.author_id,
                  "username" => comment.post.author.username,
                  "display_name" => comment.post.author.display_name
                }
              },
              "parent" => {
                "id" => parent_comment.id,
                "text" => parent_comment.text,
                "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reply_count" => 2,
                "author" => {
                  "id" => parent_comment.author_id,
                  "username" => parent_comment.author.username,
                  "display_name" => parent_comment.author.display_name
                }
              },
              "replies" => []
            }
          )
      end
    end

    context "when comment does not exist at given ID" do
      it "returns a not_found error" do
        get "/comments/0"
        expect(response.parsed_body).to eq "errors" => ["Unable to find Comment at given ID: 0"]
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "POST /comments" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment_post) { create(:post) }

    let(:comment_params) do
      {
        comment: {
          text: Faker::Lorem.question,
          post_id: comment_post.id
        }
      }
    end

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a comment" do
        expect { post "/comments", params: comment_params }
          .to change { Comment.count }.by(1)

        comment = Comment.last
        expect(comment).to have_attributes(
          text: comment_params[:comment][:text],
          author_id: user.id,
          post_id: comment_post.id,
          parent_id: nil
        )

        expect(response.parsed_body).to eq(
          {
            "id" => comment.id,
            "text" => comment.text,
            "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "current_user_following" => false,
            "author" => {
              "id" => user.id,
              "username" => user.username,
              "display_name" => user.display_name
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => comment.post.comments.count,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username,
                "display_name" => comment.post.author.display_name
              }
            },
            "parent" => nil,
            "replies" => []
          }
        )
      end

      context "with a parent" do
        let!(:parent_comment) { create(:comment, post_id: comment_post.id) }

        it "creates a comment with a parent" do
          expect { post "/comments", params: comment_params.deep_merge(comment: {parent_id: parent_comment.id}) }
            .to change { Comment.count }.by(1)

          comment = Comment.last
          expect(comment).to have_attributes(
            text: comment_params[:comment][:text],
            author_id: user.id,
            post_id: comment_post.id,
            parent_id: parent_comment.id
          )

          expect(response.parsed_body).to eq(
            {
              "id" => comment.id,
              "text" => comment.text,
              "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "reply_count" => 0,
              "current_user_following" => false,
              "author" => {
                "id" => user.id,
                "username" => user.username,
                "display_name" => user.display_name
              },
              "post" => {
                "id" => comment.post_id,
                "text" => comment.post.text,
                "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "comment_count" => comment.post.comments.count,
                "author" => {
                  "id" => comment.post.author_id,
                  "username" => comment.post.author.username,
                  "display_name" => comment.post.author.display_name
                }
              },
              "parent" => {
                "id" => parent_comment.id,
                "text" => parent_comment.text,
                "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reply_count" => 1,
                "author" => {
                  "id" => parent_comment.author_id,
                  "username" => parent_comment.author.username,
                  "display_name" => parent_comment.author.display_name
                }
              },
              "replies" => []
            }
          )
        end
      end

      context "with an invalid comment" do
        it "returns an unprocessable_entity error" do
          expect { post "/comments", params: comment_params.deep_merge(comment: {text: Faker::Lorem.sentence}) }
            .not_to change { Comment.count }

          expect(response.parsed_body).to eq "errors" => ["Text must only have questions"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "without a logged in user" do
      it "returns an unauthorized error" do
        expect { post "/comments", params: comment_params }
          .not_to change { Comment.count }

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage comments."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "PUT /comments/:id" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let(:comment_text) { Faker::Lorem.question }
    let!(:comment) { create(:comment, author_id: user.id, text: comment_text) }

    let(:comment_params) do
      {
        comment: {
          text: Faker::Lorem.question
        }
      }
    end

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "updates the comment at the given ID" do
        expect { put "/comments/#{comment.id}", params: comment_params }
          .to change { comment.reload.text }.from(comment_text).to(comment_params[:comment][:text])
          .and not_change { Comment.count }

        expect(response.parsed_body).to eq(
          {
            "id" => comment.id,
            "text" => comment_params[:comment][:text],
            "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "current_user_following" => false,
            "author" => {
              "id" => user.id,
              "username" => user.username,
              "display_name" => user.display_name
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => comment.post.comments.count,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username,
                "display_name" => comment.post.author.display_name
              }
            },
            "parent" => nil,
            "replies" => []
          }
        )
      end

      context "with replies and parent" do
        let!(:reply1) { create(:comment, :reply, post: comment.post, comment:) }
        let!(:reply2) { create(:comment, :reply, post: comment.post, comment:) }
        let!(:parent_comment) { create(:comment, post: comment.post) }

        before do
          create(:comment, :reply, post: comment.post, comment: reply2)
          create(:comment, :reply, post: comment.post, comment: reply2)
          create(:comment, :reply, post: comment.post, comment: parent_comment)
          comment.update!(parent_id: parent_comment.id)
        end

        it "includes the parent comment and the replies" do
          expect { put "/comments/#{comment.id}", params: comment_params }
            .to change { comment.reload.text }.from(comment_text).to(comment_params[:comment][:text])
            .and not_change { Comment.count }

          expect(response.parsed_body)
            .to eq(
              {
                "id" => comment.id,
                "text" => comment_params[:comment][:text],
                "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reply_count" => 2,
                "current_user_following" => false,
                "author" => {
                  "id" => user.id,
                  "username" => user.username,
                  "display_name" => user.display_name
                },
                "post" => {
                  "id" => comment.post_id,
                  "text" => comment.post.text,
                  "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "comment_count" => comment.post.comments.count,
                  "author" => {
                    "id" => comment.post.author_id,
                    "username" => comment.post.author.username,
                    "display_name" => comment.post.author.display_name
                  }
                },
                "parent" => {
                  "id" => parent_comment.id,
                  "text" => parent_comment.text,
                  "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 2,
                  "author" => {
                    "id" => parent_comment.author_id,
                    "username" => parent_comment.author.username,
                    "display_name" => parent_comment.author.display_name
                  }
                },
                "replies" => [
                  {
                    "id" => reply2.id,
                    "text" => reply2.text,
                    "created_at" => reply2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                    "reply_count" => 2,
                    "author" => {
                      "id" => reply2.author_id,
                      "username" => reply2.author.username,
                      "display_name" => reply2.author.display_name
                    }
                  },
                  {
                    "id" => reply1.id,
                    "text" => reply1.text,
                    "created_at" => reply1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                    "reply_count" => 0,
                    "author" => {
                      "id" => reply1.author_id,
                      "username" => reply1.author.username,
                      "display_name" => reply1.author.display_name
                    }
                  }
                ]
              }
            )
        end
      end

      context "when comment does not exist at given ID" do
        it "returns a not_found error" do
          expect { put "/comments/0", params: comment_params }
            .to not_change { comment.reload.text }
            .and not_change { Comment.count }

          expect(response.parsed_body).to eq "errors" => ["Unable to find Comment at given ID: 0"]
          expect(response).to have_http_status :not_found
        end
      end

      context "when author of comment is different from current user" do
        let(:password) { "P@ssword1" }
        let!(:user2) { create(:user, password:) }

        before do
          get "/sign_out"
          post "/sign_in", params: {user: {login: user2.username, password:}}
        end

        it "returns an unauthorized error" do
          expect { put "/comments/#{comment.id}", params: comment_params }
            .to not_change { comment.reload.text }
            .and not_change { Comment.count }

          expect(response.parsed_body).to eq "errors" => ["Cannot update other's comments."]
          expect(response).to have_http_status :unauthorized
        end
      end

      context "with an invalid comment" do
        it "returns an unprocessable_entity error" do
          expect do
            put "/comments/#{comment.id}", params: comment_params.deep_merge(comment: {text: Faker::Lorem.sentence})
          end
            .to not_change { comment.reload.text }
            .and not_change { Comment.count }

          expect(response.parsed_body).to eq "errors" => ["Text must only have questions"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "without a logged in user" do
      it "returns an unauthorized error" do
        expect { put "/comments/#{comment.id}", params: comment_params }
          .to not_change { comment.reload.text }
          .and not_change { Comment.count }

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage comments."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /comments/:id" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment) { create(:comment, author_id: user.id) }

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes the comment at the given ID" do
        expect { delete "/comments/#{comment.id}" }
          .to change { Comment.count }.by(-1)
          .and change { Comment.find_by(id: comment.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "id" => comment.id,
            "text" => comment.text,
            "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "current_user_following" => false,
            "author" => {
              "id" => user.id,
              "username" => user.username,
              "display_name" => user.display_name
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 0,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username,
                "display_name" => comment.post.author.display_name
              }
            },
            "parent" => nil,
            "replies" => []
          }
        )
      end

      context "with replies and parent" do
        let!(:reply1) { create(:comment, :reply, post: comment.post, comment:) }
        let!(:reply2) { create(:comment, :reply, post: comment.post, comment:) }

        let!(:child_reply1) { create(:comment, :reply, post: comment.post, comment: reply2) }
        let!(:child_reply2) { create(:comment, :reply, post: comment.post, comment: reply2) }

        let!(:parent_comment) { create(:comment, post: comment.post) }

        before do
          create(:comment, :reply, post: comment.post, comment: parent_comment)
          comment.update!(parent_id: parent_comment.id)
        end

        it "includes the parent comment and deletes the replies" do
          expect { delete "/comments/#{comment.id}" }
            .to change { Comment.count }.by(-5)
            .and change { Comment.find_by(id: comment.id).present? }.from(true).to(false)
            .and change { Comment.find_by(id: reply1.id).present? }.from(true).to(false)
            .and change { Comment.find_by(id: reply2.id).present? }.from(true).to(false)
            .and change { Comment.find_by(id: child_reply1.id).present? }.from(true).to(false)
            .and change { Comment.find_by(id: child_reply2.id).present? }.from(true).to(false)

          expect(response.parsed_body)
            .to eq(
              {
                "id" => comment.id,
                "text" => comment.text,
                "created_at" => comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reply_count" => 0,
                "current_user_following" => false,
                "author" => {
                  "id" => user.id,
                  "username" => user.username,
                  "display_name" => user.display_name
                },
                "post" => {
                  "id" => comment.post_id,
                  "text" => comment.post.text,
                  "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "comment_count" => 1,
                  "author" => {
                    "id" => comment.post.author_id,
                    "username" => comment.post.author.username,
                    "display_name" => comment.post.author.display_name
                  }
                },
                "parent" => {
                  "id" => parent_comment.id,
                  "text" => parent_comment.text,
                  "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 1,
                  "author" => {
                    "id" => parent_comment.author_id,
                    "username" => parent_comment.author.username,
                    "display_name" => parent_comment.author.display_name
                  }
                },
                "replies" => []
              }
            )
        end
      end

      context "when comment does not exist at given ID" do
        it "returns a not_found error" do
          expect { delete "/comments/0" }
            .to not_change { Comment.count }
            .and not_change { Comment.find_by(id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find Comment at given ID: 0"]
          expect(response).to have_http_status :not_found
        end
      end

      context "when author of comment is different from current user" do
        let(:password) { "P@ssword1" }
        let!(:user2) { create(:user, password:) }

        before do
          get "/sign_out"
          post "/sign_in", params: {user: {login: user2.username, password:}}
        end

        it "returns an unauthorized error" do
          expect { delete "/comments/#{comment.id}" }
            .to not_change { Comment.count }
            .and not_change { Comment.find_by(id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Cannot delete other's comments."]
          expect(response).to have_http_status :unauthorized
        end
      end

      context "when an error is raised trying to destroy comment" do
        before do
          allow_any_instance_of(Comment).to receive(:destroy).and_return(false)
          allow_any_instance_of(Comment)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable_entity error" do
          expect { delete "/comments/#{comment.id}" }
            .to not_change { Comment.count }
            .and not_change { Comment.find_by(id: comment.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "without a logged in user" do
      it "returns an unauthorized error" do
        expect { delete "/comments/#{comment.id}" }
          .to not_change { Comment.count }
          .and not_change { Comment.find_by(id: comment.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage comments."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "GET /users/:user_id/comments" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }
    let!(:comment1) { create(:comment, author_id: user.id) }
    let!(:comment2) { create(:comment, author_id: user.id) }
    let!(:comment3) { create(:comment, author_id: user.id) }

    let!(:self_reply) do
      create(:comment, :reply, comment: comment2, author_id: user.id, post_id: comment2.post_id)
    end

    before do
      create_list(:comment, 5)
      create_list(:comment, 5, :reply)
    end

    it "gets the user's comments by latest created at date" do
      get "/users/#{user.id}/comments"

      expect(response.parsed_body).to eq(
        [
          {
            "id" => self_reply.id,
            "text" => self_reply.text,
            "created_at" => self_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "author" => {
              "id" => self_reply.author_id,
              "username" => self_reply.author.username,
              "display_name" => self_reply.author.display_name
            },
            "post" => {
              "id" => self_reply.post_id,
              "text" => self_reply.post.text,
              "created_at" => self_reply.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => self_reply.post.author_id,
                "username" => self_reply.post.author.username,
                "display_name" => self_reply.post.author.display_name
              }
            },
            "parent" => {
              "id" => comment2.id,
              "text" => comment2.text,
              "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "reply_count" => 1,
              "author" => {
                "id" => comment2.author_id,
                "username" => comment2.author.username,
                "display_name" => comment2.author.display_name
              }
            }
          },
          {
            "id" => comment3.id,
            "text" => comment3.text,
            "created_at" => comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "author" => {
              "id" => comment3.author_id,
              "username" => comment3.author.username,
              "display_name" => comment3.author.display_name
            },
            "post" => {
              "id" => comment3.post_id,
              "text" => comment3.post.text,
              "created_at" => comment3.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => comment3.post.author_id,
                "username" => comment3.post.author.username,
                "display_name" => comment3.post.author.display_name
              }
            },
            "parent" => nil
          },
          {
            "id" => comment2.id,
            "text" => comment2.text,
            "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 1,
            "author" => {
              "id" => comment2.author_id,
              "username" => comment2.author.username,
              "display_name" => comment2.author.display_name
            },
            "post" => {
              "id" => comment2.post_id,
              "text" => comment2.post.text,
              "created_at" => comment2.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => comment2.post.author_id,
                "username" => comment2.post.author.username,
                "display_name" => comment2.post.author.display_name
              }
            },
            "parent" => nil
          },
          {
            "id" => comment1.id,
            "text" => comment1.text,
            "created_at" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "reply_count" => 0,
            "author" => {
              "id" => comment1.author_id,
              "username" => comment1.author.username,
              "display_name" => comment1.author.display_name
            },
            "post" => {
              "id" => comment1.post_id,
              "text" => comment1.post.text,
              "created_at" => comment1.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => comment1.post.author_id,
                "username" => comment1.post.author.username,
                "display_name" => comment1.post.author.display_name
              }
            },
            "parent" => nil
          }
        ]
      )
    end

    context "when User does not exist at given ID" do
      it "returns an empty array" do
        get "/users/0/comments"
        expect(response.parsed_body).to eq []
      end
    end
  end

  describe "GET /users/:user_id/linked_comments" do
    context "when user exists" do
      let(:password) { "P0s+erk1d" }
      let!(:user) { create(:user, password:) }

      let(:user_comment_like_count) { 5 }
      let(:user_comment_repost_count) { 2 }
      let(:user_comment_comment_count) { 4 }

      let(:user_reply_like_count) { 3 }
      let(:user_reply_repost_count) { 1 }
      let(:user_reply_comment_count) { 7 }

      let(:reposted_comment_like_count) { 6 }
      let(:reposted_comment_repost_count) { 7 }
      let(:reposted_comment_comment_count) { 2 }

      let(:reposted_reply_like_count) { 9 }
      let(:reposted_reply_repost_count) { 4 }
      let(:reposted_reply_comment_count) { 1 }

      let!(:reposted_comment) do
        create(
          :comment,
          :liked,
          :reposted,
          :replied,
          like_count: reposted_comment_like_count,
          reply_count: reposted_comment_comment_count,
          repost_count: reposted_comment_repost_count
        )
      end
      let!(:reposted_reply) do
        create(
          :comment,
          :reply,
          :liked,
          :reposted,
          :replied,
          like_count: reposted_reply_like_count,
          reply_count: reposted_reply_comment_count,
          repost_count: reposted_reply_repost_count
        )
      end
      let!(:user_comment) do
        create(
          :comment,
          :liked,
          :reposted,
          :replied,
          like_count: user_comment_like_count,
          reply_count: user_comment_comment_count,
          repost_count: user_comment_repost_count,
          author_id: user.id
        )
      end
      let!(:user_reply) do
        create(
          :comment,
          :reply,
          :liked,
          :reposted,
          :replied,
          like_count: user_reply_like_count,
          reply_count: user_reply_comment_count,
          repost_count: user_reply_repost_count,
          author_id: user.id
        )
      end
      let!(:reposted_reply_repost) { create(:comment_repost, message_id: reposted_reply.id, user:) }
      let!(:reposted_comment_repost) { create(:comment_repost, message_id: reposted_comment.id, user:) }

      before do
        create_list(:post, 4, :liked, :commented, :reposted)
        create_list(:comment, 4, :liked, :replied, :reposted)
        create_list(:comment, 4, :reply, :liked, :replied, :reposted)

        create_list(:post_repost, 2, user:)
        create_list(:post, 3, :liked, :commented, :reposted, author_id: user.id)
      end

      it "returns their own and reposted comments" do
        get "/users/#{user.id}/linked_comments"
        expect(response.parsed_body).to eq(
          {
            "user" => {
              "username" => user.username,
              "display_name" => user.display_name
            },
            "comments" => [
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
                "id" => user_reply.id,
                "text" => user_reply.text,
                "created_at" => user_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Comment",
                "like_count" => user_reply_like_count,
                "repost_count" => user_reply_repost_count,
                "comment_count" => user_reply_comment_count,
                "post_date" => user_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reposted_by" => nil,
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "replying_to" => [user_reply.parent.author.username, user_reply.post.author.username],
                "author" => {
                  "id" => user_reply.author_id,
                  "username" => user_reply.author.username,
                  "display_name" => user_reply.author.display_name
                }
              },
              {
                "id" => user_comment.id,
                "text" => user_comment.text,
                "created_at" => user_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "post_type" => "Comment",
                "like_count" => user_comment_like_count,
                "repost_count" => user_comment_repost_count,
                "comment_count" => user_comment_comment_count,
                "post_date" => user_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reposted_by" => nil,
                "user_liked" => false,
                "user_reposted" => false,
                "user_followed" => false,
                "replying_to" => [user_comment.post.author.username],
                "author" => {
                  "id" => user_comment.author_id,
                  "username" => user_comment.author.username,
                  "display_name" => user_comment.author.display_name
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
          create(:comment_like, user: current_user, message_id: reposted_comment.id)
          create(:comment_like, user: current_user, message_id: user_comment.id)

          create(:comment_repost, user: current_user, message_id: reposted_reply.id)
          create(:comment_repost, user: current_user, message_id: user_comment.id)

          create(:follow, follower: current_user, followee: reposted_reply.author)
          create(:follow, follower: current_user, followee: user_reply.author)

          post("/sign_in", params: {user: {login: current_user.username, password: current_user_password}})
        end

        it "returns whether or not the logged in user liked or reposted the comment or followed the author" do
          get "/users/#{user.id}/linked_comments"
          expect(response.parsed_body).to eq(
            {
              "user" => {
                "username" => user.username,
                "display_name" => user.display_name
              },
              "comments" => [
                {
                  "id" => reposted_comment.id,
                  "text" => reposted_comment.text,
                  "created_at" => reposted_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => reposted_comment_like_count + 1,
                  "repost_count" => reposted_comment_repost_count + 1,
                  "comment_count" => reposted_comment_comment_count,
                  "post_date" => reposted_comment_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => user.display_name,
                  "user_liked" => true,
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
                  "id" => reposted_reply.id,
                  "text" => reposted_reply.text,
                  "created_at" => reposted_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "CommentRepost",
                  "like_count" => reposted_reply_like_count,
                  "repost_count" => reposted_reply_repost_count + 1 + 1,
                  "comment_count" => reposted_reply_comment_count,
                  "post_date" => reposted_reply_repost.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => user.display_name,
                  "user_liked" => false,
                  "user_reposted" => true,
                  "user_followed" => true,
                  "replying_to" => [reposted_reply.parent.author.username, reposted_reply.post.author.username],
                  "author" => {
                    "id" => reposted_reply.author_id,
                    "username" => reposted_reply.author.username,
                    "display_name" => reposted_reply.author.display_name
                  }
                },
                {
                  "id" => user_reply.id,
                  "text" => user_reply.text,
                  "created_at" => user_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Comment",
                  "like_count" => user_reply_like_count,
                  "repost_count" => user_reply_repost_count,
                  "comment_count" => user_reply_comment_count,
                  "post_date" => user_reply.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => nil,
                  "user_liked" => false,
                  "user_reposted" => false,
                  "user_followed" => true,
                  "replying_to" => [user_reply.parent.author.username, user_reply.post.author.username],
                  "author" => {
                    "id" => user_reply.author_id,
                    "username" => user_reply.author.username,
                    "display_name" => user_reply.author.display_name
                  }
                },
                {
                  "id" => user_comment.id,
                  "text" => user_comment.text,
                  "created_at" => user_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "post_type" => "Comment",
                  "like_count" => user_comment_like_count + 1,
                  "repost_count" => user_comment_repost_count + 1,
                  "comment_count" => user_comment_comment_count,
                  "post_date" => user_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reposted_by" => nil,
                  "user_liked" => true,
                  "user_reposted" => true,
                  "user_followed" => true,
                  "replying_to" => [user_comment.post.author.username],
                  "author" => {
                    "id" => user_comment.author_id,
                    "username" => user_comment.author.username,
                    "display_name" => user_comment.author.display_name
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
