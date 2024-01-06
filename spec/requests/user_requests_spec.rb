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
            "following_count" => following_count,
            "follower_count" => follower_count
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
end
