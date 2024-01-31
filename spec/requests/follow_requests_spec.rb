require "rails_helper"

RSpec.describe "Follow Requests" do
  describe "POST /follows" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }

    let(:other_user_password) { "No0bod1ee" }
    let!(:other_user) { create(:user, password: other_user_password) }

    let(:follow_params) do
      {
        follow: {
          followee_id: other_user.id
        }
      }
    end

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "creates a follow for the user" do
        expect { post "/follows", params: follow_params }
          .to change { Follow.count }.by(1)
          .and change { Follow.find_by(follower_id: user.id, followee_id: other_user.id).present? }.from(false).to(true)

        expect(response.parsed_body).to eq(
          {
            "follower_id" => user.id,
            "followee_id" => other_user.id
          }
        )
      end

      it "allows user to follow back" do
        post "/follows", params: follow_params
        get "/sign_out"
        post "/sign_in", params: {user: {login: other_user.username, password: other_user_password}}

        expect { post "/follows", params: {follow: {followee_id: user.id}} }
          .to change { Follow.count }.by(1)
          .and change { Follow.find_by(follower_id: other_user.id, followee_id: user.id).present? }.from(false).to(true)

        expect(response.parsed_body).to eq(
          {
            "follower_id" => other_user.id,
            "followee_id" => user.id
          }
        )
      end

      context "when follow could not be saved" do
        it "returns an unprocessable entity error" do
          expect { post "/follows", params: {follow: {followee_id: 0}} }
            .not_to change { Follow.count }

          expect(response.parsed_body).to eq "errors" => ["Followee must exist"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        post "/follows", params: follow_params
        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage follows."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE /follows" do
    let(:password) { "P0s+erk1d" }
    let!(:user) { create(:user, password:) }

    let(:other_user_password) { "No0bod1ee" }
    let!(:other_user) { create(:user, password: other_user_password) }

    let(:follow_params) do
      {
        follow: {
          followee_id: other_user.id
        }
      }
    end

    before { create(:follow, follower: user, followee: other_user) }

    context "when user is logged in" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "deletes a follow" do
        expect { delete "/follows", params: follow_params }
          .to change { Follow.count }.by(-1)
          .and change { Follow.find_by(follower_id: user.id, followee_id: other_user.id).present? }.from(true).to(false)

        expect(response.parsed_body).to eq(
          {
            "follower_id" => user.id,
            "followee_id" => other_user.id
          }
        )
      end

      context "when follow does not exist" do
        it "returns a not found error" do
          expect { delete "/follows", params: {follow: {followee_id: 0}} }
            .to not_change { Follow.count }
            .and not_change { Follow.find_by(follower_id: user.id, followee_id: other_user.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Unable to find follow reference."]
          expect(response).to have_http_status :not_found
        end
      end

      context "when follow could not be destroyed" do
        before do
          allow_any_instance_of(Follow).to receive(:destroy).and_return(false)
          allow_any_instance_of(Follow)
            .to receive(:errors)
            .and_return(
              double(:error_messages, full_messages: ["Something bad happened"])
            )
        end

        it "returns an unprocessable entity error" do
          expect { delete "/follows", params: follow_params }
            .to not_change { Follow.count }
            .and not_change { Follow.find_by(follower_id: user.id, followee_id: other_user.id).present? }.from(true)

          expect(response.parsed_body).to eq "errors" => ["Something bad happened"]
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when user is not logged in" do
      it "returns an unauthorized error" do
        expect { delete "/follows", params: follow_params }
          .to not_change { Follow.count }
          .and not_change { Follow.find_by(follower_id: user.id, followee_id: other_user.id).present? }.from(true)

        expect(response.parsed_body).to eq "errors" => ["Must be logged in to manage follows."]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "GET users/:username/subscriptions" do
    let!(:user) { create(:user) }

    let!(:followed_user1) { create(:user) }
    let!(:followed_user2) { create(:user) }
    let!(:followed_user3) { create(:user) }

    before do
      create(:follow, follower: user, followee: followed_user1)
      create(:follow, follower: user, followee: followed_user2)
      create(:follow, follower: user, followee: followed_user3)

      create_list(:follow, 5)
    end

    it "returns the user's followed users sorted by follow creation" do
      get "/users/#{user.username}/subscriptions"

      expect(response.parsed_body).to eq(
        {
          "id" => user.id,
          "display_name" => user.display_name,
          "username" => user.username,
          "followed_users" => [
            {
              "id" => followed_user3.id,
              "username" => followed_user3.username,
              "display_name" => followed_user3.display_name,
              "following_current_user" => false,
              "current_user_following" => false
            },
            {
              "id" => followed_user2.id,
              "username" => followed_user2.username,
              "display_name" => followed_user2.display_name,
              "following_current_user" => false,
              "current_user_following" => false
            },
            {
              "id" => followed_user1.id,
              "username" => followed_user1.username,
              "display_name" => followed_user1.display_name,
              "following_current_user" => false,
              "current_user_following" => false
            }
          ]
        }
      )
    end

    context "when logged in" do
      let(:password) { "P0s+erk1d" }
      let!(:logged_in_user) { create(:user, password:) }

      before { post "/sign_in", params: {user: {login: logged_in_user.username, password:}} }

      context "with users who follow the current user" do
        before do
          create(:follow, followee: logged_in_user, follower: followed_user1)
          create(:follow, followee: logged_in_user, follower: followed_user3)
        end

        it "notates them" do
          get "/users/#{user.username}/subscriptions"

          expect(response.parsed_body).to eq(
            {
              "id" => user.id,
              "display_name" => user.display_name,
              "username" => user.username,
              "followed_users" => [
                {
                  "id" => followed_user3.id,
                  "username" => followed_user3.username,
                  "display_name" => followed_user3.display_name,
                  "following_current_user" => true,
                  "current_user_following" => false
                },
                {
                  "id" => followed_user2.id,
                  "username" => followed_user2.username,
                  "display_name" => followed_user2.display_name,
                  "following_current_user" => false,
                  "current_user_following" => false
                },
                {
                  "id" => followed_user1.id,
                  "username" => followed_user1.username,
                  "display_name" => followed_user1.display_name,
                  "following_current_user" => true,
                  "current_user_following" => false
                }
              ]
            }
          )
        end
      end

      context "with users who the current user follows" do
        before do
          create(:follow, follower: logged_in_user, followee: followed_user1)
          create(:follow, follower: logged_in_user, followee: followed_user2)
        end

        it "notates them" do
          get "/users/#{user.username}/subscriptions"

          expect(response.parsed_body).to eq(
            {
              "id" => user.id,
              "display_name" => user.display_name,
              "username" => user.username,
              "followed_users" => [
                {
                  "id" => followed_user3.id,
                  "username" => followed_user3.username,
                  "display_name" => followed_user3.display_name,
                  "following_current_user" => false,
                  "current_user_following" => false
                },
                {
                  "id" => followed_user2.id,
                  "username" => followed_user2.username,
                  "display_name" => followed_user2.display_name,
                  "following_current_user" => false,
                  "current_user_following" => true
                },
                {
                  "id" => followed_user1.id,
                  "username" => followed_user1.username,
                  "display_name" => followed_user1.display_name,
                  "following_current_user" => false,
                  "current_user_following" => true
                }
              ]
            }
          )
        end
      end
    end

    context "when user does not exist" do
      it "returns a not found error" do
        get "/users/0/subscriptions"
        expect(response.parsed_body).to eq "errors" => ["Unable to find user."]
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "GET users/:username/followers" do
    let!(:user) { create(:user) }

    let!(:follower1) { create(:user) }
    let!(:follower2) { create(:user) }
    let!(:follower3) { create(:user) }

    before do
      create(:follow, followee: user, follower: follower1)
      create(:follow, followee: user, follower: follower2)
      create(:follow, followee: user, follower: follower3)

      create_list(:follow, 5)
    end

    it "returns the user's followers" do
      get "/users/#{user.username}/followers"

      expect(response.parsed_body).to eq(
        {
          "id" => user.id,
          "display_name" => user.display_name,
          "username" => user.username,
          "followers" => [
            {
              "id" => follower3.id,
              "username" => follower3.username,
              "display_name" => follower3.display_name,
              "following_current_user" => false,
              "current_user_following" => false
            },
            {
              "id" => follower2.id,
              "username" => follower2.username,
              "display_name" => follower2.display_name,
              "following_current_user" => false,
              "current_user_following" => false
            },
            {
              "id" => follower1.id,
              "username" => follower1.username,
              "display_name" => follower1.display_name,
              "following_current_user" => false,
              "current_user_following" => false
            }
          ]
        }
      )
    end

    context "when logged in" do
      let(:password) { "P0s+erk1d" }
      let!(:logged_in_user) { create(:user, password:) }

      before { post "/sign_in", params: {user: {login: logged_in_user.username, password:}} }

      context "with users who follow the current user" do
        before do
          create(:follow, followee: logged_in_user, follower: follower1)
          create(:follow, followee: logged_in_user, follower: follower3)
        end

        it "notates them" do
          get "/users/#{user.username}/followers"

          expect(response.parsed_body).to eq(
            {
              "id" => user.id,
              "display_name" => user.display_name,
              "username" => user.username,
              "followers" => [
                {
                  "id" => follower3.id,
                  "username" => follower3.username,
                  "display_name" => follower3.display_name,
                  "following_current_user" => true,
                  "current_user_following" => false
                },
                {
                  "id" => follower2.id,
                  "username" => follower2.username,
                  "display_name" => follower2.display_name,
                  "following_current_user" => false,
                  "current_user_following" => false
                },
                {
                  "id" => follower1.id,
                  "username" => follower1.username,
                  "display_name" => follower1.display_name,
                  "following_current_user" => true,
                  "current_user_following" => false
                }
              ]
            }
          )
        end
      end

      context "with users who the current user follows" do
        before do
          create(:follow, follower: logged_in_user, followee: follower2)
          create(:follow, follower: logged_in_user, followee: follower3)
        end

        it "notates them" do
          get "/users/#{user.username}/followers"

          expect(response.parsed_body).to eq(
            {
              "id" => user.id,
              "display_name" => user.display_name,
              "username" => user.username,
              "followers" => [
                {
                  "id" => follower3.id,
                  "username" => follower3.username,
                  "display_name" => follower3.display_name,
                  "following_current_user" => false,
                  "current_user_following" => true
                },
                {
                  "id" => follower2.id,
                  "username" => follower2.username,
                  "display_name" => follower2.display_name,
                  "following_current_user" => false,
                  "current_user_following" => true
                },
                {
                  "id" => follower1.id,
                  "username" => follower1.username,
                  "display_name" => follower1.display_name,
                  "following_current_user" => false,
                  "current_user_following" => false
                }
              ]
            }
          )
        end
      end
    end

    context "when user does not exist" do
      it "returns a not found error" do
        get "/users/0/followers"
        expect(response.parsed_body).to eq "errors" => ["Unable to find user."]
        expect(response).to have_http_status :not_found
      end
    end
  end
end
