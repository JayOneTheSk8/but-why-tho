require "rails_helper"

RSpec.describe "Authentication" do
  describe "POST /sign_up" do
    let(:user_params) do
      {
        user: {
          username: "Daniel123",
          display_name: "Daniel 123",
          email: "danny123@email.com",
          password: "RealLifePass123!",
          password_confirmation: "RealLifePass123!"
        }
      }
    end

    shared_examples "a User is created" do
      it "signs up a user" do
        expect { post "/sign_up", params: }
          .to change(User, :count).by(1)
          .and change(UserMailer.deliveries, :count).by(1)

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
              "email" => u.email,
              "display_name" => u.display_name
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

  describe "POST /sign_in" do
    let(:password) { "S0meP@55!" }
    let!(:user) { create(:user, password:) }
    let(:username_params) do
      {
        user: {
          login: user.username,
          password:
        }
      }
    end
    let(:email_params) do
      {
        user: {
          login: user.email,
          password:
        }
      }
    end

    shared_examples "a user is logged in" do
      it "sets a session token for the user" do
        post("/sign_in", params:)
        expect(session[:session_token]).to eq user.reload.session_token
      end

      it "returns the user's data" do
        post("/sign_in", params:)

        expect(session[:session_token]).to eq user.reload.session_token
        expect(response.parsed_body).to eq(
          {
            "user" => {
              "id" => user.id,
              "username" => user.username,
              "email" => user.email,
              "display_name" => user.display_name
            }
          }
        )
      end
    end

    context "with a username" do
      let(:params) { username_params }

      it_behaves_like "a user is logged in"

      context "when passed username capitalisation is different" do
        let(:params) { username_params.deep_merge(user: {login: user.username.upcase}) }

        it_behaves_like "a user is logged in"
      end
    end

    context "with an email" do
      let(:params) { email_params }

      it_behaves_like "a user is logged in"

      context "when passed email capitalisation is different" do
        let(:params) { email_params.deep_merge(user: {login: user.email.upcase}) }

        it_behaves_like "a user is logged in"
      end
    end

    context "with bad credentials" do
      let(:params) { username_params.deep_merge(user: {password: "password"}) }

      it "does not log a user in" do
        post("/sign_in", params:)

        expect(session[:session_token]).to be_nil
        expect(response.parsed_body).to eq "errors" => ["Incorrect email/username or password"]
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "GET /sign_out" do
    let(:password) { "Ano+herP@55!" }
    let!(:user) { create(:user, password:) }

    context "with a logged in user" do
      before { post "/sign_in", params: {user: {login: user.username, password:}} }

      it "resets the user's session token" do
        expect { get "/sign_out" }.to change { user.reload.session_token }
      end

      it "nullifies the existing session token" do
        expect { get "/sign_out" }.to change { session[:session_token] }.to(nil)
      end

      it "returns an 'ok' status" do
        get "/sign_out"
        expect(response).to have_http_status :ok
      end
    end

    context "without a logged in user" do
      it "returns an 'not_found' status" do
        get "/sign_out"

        expect(response.parsed_body).to eq "errors" => ["No user logged in"]
        expect(response).to have_http_status :not_found
      end
    end
  end
end
