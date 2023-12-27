require "rails_helper"

RSpec.describe "Authentication" do
  describe "/sign_up" do
    let(:user_params) do
      {
        user: {
          username: "Daniel123",
          email: "danny123@email.com",
          password: "RealLifePass123!",
          password_confirmation: "RealLifePass123!"
        }
      }
    end

    shared_examples "a User is created" do
      it "signs up a user" do
        expect { post "/sign_up", params: }.to change(User, :count).by(1)

        username = params[:user][:username]
        email = params[:user][:email]
        password = params[:user][:password]

        u = User.find_by!(username:, email:)
        expect(u.authenticate(password)).to be_present

        expect(response.parsed_body).to eq(
          {
            "user" => {
              "id" => u.id,
              "username" => u.username,
              "email" => u.email
            }
          }
        )
      end
    end

    context "with all fields" do
      let(:params) { user_params }

      it_behaves_like "a User is created"
    end

    context "when password confimation is blank" do
      let(:params) { user_params.deep_merge(user: {password_confirmation: nil}) }

      it_behaves_like "a User is created"
    end

    context "without existing email" do
      before { create(:user, email: user_params[:user][:email]) }

      it "returns an existing email response" do
        post "/sign_up", params: user_params
        expect(response.parsed_body).to eq "errors" => ["Email has already been taken"]
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "without existing username" do
      before { create(:user, username: user_params[:user][:username]) }

      it "returns an existing username response" do
        post "/sign_up", params: user_params
        expect(response.parsed_body).to eq "errors" => ["Username has already been taken"]
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "without password" do
      it "returns a blank password error response" do
        post "/sign_up", params: user_params.deep_merge(user: {password: nil, password_confirmation: nil})
        expect(response.parsed_body).to eq "errors" => ["Password can't be blank"]
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "when password confimation does not match" do
      it "returns a mismatching password error response" do
        post "/sign_up", params: user_params.deep_merge(user: {password_confirmation: "somethingelse"})
        expect(response.parsed_body).to eq "errors" => ["Password confirmation doesn't match Password"]
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end
end
