require "rails_helper"

RSpec.describe "Email Confirmations" do
  let!(:user) { create(:user, :unconfirmed) }

  describe "POST /email_confirmations" do
    let(:user_params) { {user: {email: user.email} } }

    it "sends a new confirmation email to the user" do
      expect { post "/email_confirmations", params: user_params }
        .to change { UserMailer.deliveries.count }.by(1)
    end

    it "searches by downcased email" do
      expect { post "/email_confirmations", params: user_params.deep_merge(user: {email: user.email.upcase}) }
        .to change { UserMailer.deliveries.count }.by(1)
    end

    context "when user is already confirmed" do
      before { user.confirm! }

      it "returns a not_found error" do
        post "/email_confirmations", params: user_params
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "GET /email_confirmations/:confirmation_token/edit" do
    let(:token) { user.generate_confirmation_token }

    it "confirms the user" do
      expect { get "/email_confirmations/#{token}/edit" }
        .to change { user.reload.confirmed? }.from(false).to(true)
    end

    context "with a bad confirmation token" do
      it "returns a not_found error" do
        get "/email_confirmations/abc123/edit"
        expect(response).to have_http_status :not_found
      end
    end
  end
end
