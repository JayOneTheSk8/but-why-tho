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
            "author" => {
              "id" => comment.author_id,
              "username" => comment.author.username
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => comment.post.comments.count,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username
              }
            },
            "parent" => nil,
            "replies" => []
          }
        )
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
              "author" => {
                "id" => comment.author_id,
                "username" => comment.author.username
              },
              "post" => {
                "id" => comment.post_id,
                "text" => comment.post.text,
                "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "comment_count" => comment.post.comments.count,
                "author" => {
                  "id" => comment.post.author_id,
                  "username" => comment.post.author.username
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
                    "username" => reply2.author.username
                  }
                },
                {
                  "id" => reply1.id,
                  "text" => reply1.text,
                  "created_at" => reply1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 0,
                  "author" => {
                    "id" => reply1.author_id,
                    "username" => reply1.author.username
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
              "author" => {
                "id" => comment.author_id,
                "username" => comment.author.username
              },
              "post" => {
                "id" => comment.post_id,
                "text" => comment.post.text,
                "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "comment_count" => comment.post.comments.count,
                "author" => {
                  "id" => comment.post.author_id,
                  "username" => comment.post.author.username
                }
              },
              "parent" => {
                "id" => parent_comment.id,
                "text" => parent_comment.text,
                "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                "reply_count" => 2,
                "author" => {
                  "id" => parent_comment.author_id,
                  "username" => parent_comment.author.username
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
            "author" => {
              "id" => user.id,
              "username" => user.username
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => comment.post.comments.count,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username
              }
            },
            "parent" => nil,
            "replies" => []
          }
        )
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
            "author" => {
              "id" => user.id,
              "username" => user.username
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => comment.post.comments.count,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username
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
                "author" => {
                  "id" => user.id,
                  "username" => user.username
                },
                "post" => {
                  "id" => comment.post_id,
                  "text" => comment.post.text,
                  "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "comment_count" => comment.post.comments.count,
                  "author" => {
                    "id" => comment.post.author_id,
                    "username" => comment.post.author.username
                  }
                },
                "parent" => {
                  "id" => parent_comment.id,
                  "text" => parent_comment.text,
                  "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 2,
                  "author" => {
                    "id" => parent_comment.author_id,
                    "username" => parent_comment.author.username
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
                      "username" => reply2.author.username
                    }
                  },
                  {
                    "id" => reply1.id,
                    "text" => reply1.text,
                    "created_at" => reply1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                    "reply_count" => 0,
                    "author" => {
                      "id" => reply1.author_id,
                      "username" => reply1.author.username
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
            "author" => {
              "id" => user.id,
              "username" => user.username
            },
            "post" => {
              "id" => comment.post_id,
              "text" => comment.post.text,
              "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 0,
              "author" => {
                "id" => comment.post.author_id,
                "username" => comment.post.author.username
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
                "author" => {
                  "id" => user.id,
                  "username" => user.username
                },
                "post" => {
                  "id" => comment.post_id,
                  "text" => comment.post.text,
                  "created_at" => comment.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "comment_count" => 1,
                  "author" => {
                    "id" => comment.post.author_id,
                    "username" => comment.post.author.username
                  }
                },
                "parent" => {
                  "id" => parent_comment.id,
                  "text" => parent_comment.text,
                  "created_at" => parent_comment.created_at.strftime("%Y-%m-%dT%T.%LZ"),
                  "reply_count" => 1,
                  "author" => {
                    "id" => parent_comment.author_id,
                    "username" => parent_comment.author.username
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
              "username" => self_reply.author.username
            },
            "post" => {
              "id" => self_reply.post_id,
              "text" => self_reply.post.text,
              "created_at" => self_reply.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => self_reply.post.author_id,
                "username" => self_reply.post.author.username
              }
            },
            "parent" => {
              "id" => comment2.id,
              "text" => comment2.text,
              "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "reply_count" => 1,
              "author" => {
                "id" => comment2.author_id,
                "username" => comment2.author.username
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
              "username" => comment3.author.username
            },
            "post" => {
              "id" => comment3.post_id,
              "text" => comment3.post.text,
              "created_at" => comment3.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => comment3.post.author_id,
                "username" => comment3.post.author.username
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
              "username" => comment2.author.username
            },
            "post" => {
              "id" => comment2.post_id,
              "text" => comment2.post.text,
              "created_at" => comment2.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => comment2.post.author_id,
                "username" => comment2.post.author.username
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
              "username" => comment1.author.username
            },
            "post" => {
              "id" => comment1.post_id,
              "text" => comment1.post.text,
              "created_at" => comment1.post.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "comment_count" => 1,
              "author" => {
                "id" => comment1.post.author_id,
                "username" => comment1.post.author.username
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
end
