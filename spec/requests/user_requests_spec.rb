require "rails_helper"

RSpec.describe "User Requests" do
  describe "GET /users/:username" do
    let!(:user) { create(:user) }
    let(:user_response) do
      {
        "id" => user.id,
        "username" => user.username,
        "display_name" => user.display_name,
        "email" => user.email,
        "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
        "post_count" => 0,
        "current_user_following" => false,
        "following_count" => 0,
        "follower_count" => 0
      }
    end

    it "returns the user's information" do
      get "/users/#{user.username}"
      expect(response.parsed_body).to eq user_response
    end

    it "ignores case" do
      get "/users/#{user.username.upcase}"
      expect(response.parsed_body).to eq user_response
    end

    context "with follows and subscriptions" do
      let(:following_count) { 7 }
      let(:follower_count) { 5 }

      before do
        create_list(:follow, rand(5..10))
        create_list(:follow, following_count, follower: user)
        create_list(:follow, follower_count, followee: user)
      end

      it "returns the appropriate count" do
        get "/users/#{user.username}"
        expect(response.parsed_body).to eq(
          {
            "id" => user.id,
            "username" => user.username,
            "display_name" => user.display_name,
            "email" => user.email,
            "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_count" => 0,
            "current_user_following" => false,
            "following_count" => following_count,
            "follower_count" => follower_count
          }
        )
      end
    end

    context "with posts" do
      let(:post_count) { 3 }

      before do
        create_list(:post, rand(5..10))
        create_list(:post, post_count, author_id: user.id)
      end

      it "returns the appropriate count" do
        get "/users/#{user.username}"
        expect(response.parsed_body).to eq(
          {
            "id" => user.id,
            "username" => user.username,
            "display_name" => user.display_name,
            "email" => user.email,
            "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_count" => post_count,
            "current_user_following" => false,
            "following_count" => 0,
            "follower_count" => 0
          }
        )
      end
    end

    context "when current user is following the user" do
      let!(:current_user) { create(:user) }

      before do
        post("/sign_in", params: {user: {login: current_user.username, password: current_user.password}})
      end

      it "returns if the current user follows the user" do
        get "/users/#{user.username}"
        expect(response.parsed_body).to eq(
          {
            "id" => user.id,
            "username" => user.username,
            "display_name" => user.display_name,
            "email" => user.email,
            "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_count" => 0,
            "current_user_following" => false,
            "following_count" => 0,
            "follower_count" => 0
          }
        )

        create(:follow, follower: current_user, followee: user)

        get "/users/#{user.username}"
        expect(response.parsed_body).to eq(
          {
            "id" => user.id,
            "username" => user.username,
            "display_name" => user.display_name,
            "email" => user.email,
            "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_count" => 0,
            "current_user_following" => true,
            "following_count" => 0,
            "follower_count" => 1
          }
        )
      end
    end

    context "when user does not exist at the passed username" do
      it "returns a not found error" do
        get "/users/iamnotreal"
        expect(response.parsed_body).to eq "errors" => ["This account doesn't exist"]
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "PUT /users/:id" do
    let!(:user) { create(:user) }
    let(:display_name) { user.display_name }
    let(:email) { user.email }

    let(:updated_display_name) { "New Name" }
    let(:updated_email) { "newemail@gmail.com" }
    let(:params) { {user: {display_name: updated_display_name, email: updated_email}} }

    context "when logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password: user.password}} }

      context "when the current user is the user being updated" do
        it "updates the user with the passed params" do
          expect { put("/users/#{user.id}", params:) }
            .to change { user.reload.display_name }.from(display_name).to(updated_display_name)
            .and change { user.reload.email }.from(email).to(updated_email)
            .and change { user.reload.updated_at }
            .and not_change { user.reload.username }
            .and not_change { user.reload.session_token }

          expect(response.parsed_body).to eq(
            {
              "id" => user.id,
              "username" => user.username,
              "display_name" => updated_display_name,
              "email" => updated_email,
              "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_count" => 0,
              "current_user_following" => false,
              "following_count" => 0,
              "follower_count" => 0
            }
          )
        end

        it "does not allow password updates" do
          expect { put "/users/#{user.id}", params: params.deep_merge(user: {password: "newpass"}) }
            .to change { user.reload.display_name }.from(display_name).to(updated_display_name)
            .and change { user.reload.email }.from(email).to(updated_email)
            .and change { user.reload.updated_at }
            .and not_change { user.reload.password_digest }

          expect(response.parsed_body).to eq(
            {
              "id" => user.id,
              "username" => user.username,
              "display_name" => updated_display_name,
              "email" => updated_email,
              "created_at" => user.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_count" => 0,
              "current_user_following" => false,
              "following_count" => 0,
              "follower_count" => 0
            }
          )
        end

        context "when there was a problem updating the user" do
          it "returns an unprocessable entity error" do
            put "/users/#{user.id}", params: params.deep_merge(user: {display_name: ""})
            expect(response.parsed_body).to eq "errors" => ["Display name can't be blank"]
            expect(response).to have_http_status :unprocessable_entity
          end
        end
      end

      context "when the current user is not the user being updated" do
        it "returns an unauthorized error" do
          put("/users/0", params:)
          expect(response.parsed_body).to eq "errors" => ["This account is inaccessible"]
          expect(response).to have_http_status :unauthorized
        end
      end
    end

    context "when not logged in" do
      it "returns an unauthorized error" do
        put("/users/#{user.id}", params:)
        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage users."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end
end
