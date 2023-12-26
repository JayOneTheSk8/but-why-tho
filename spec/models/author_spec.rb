require "rails_helper"

RSpec.describe Author do
  let(:author) { build(:author) }

  describe "#valid?" do
    %i[
      email
      username
    ].each do |attr|
      it "is invalid with a nil #{attr}" do
        author.assign_attributes(attr => nil)
        expect(author).not_to be_valid
        expect(
          author.errors.full_messages.map(&:downcase)
        ).to include "#{attr} can't be blank"
      end
    end

    describe "email attribute" do
      it "does not allow for malformed email addresses" do
        %w[
          bademail.com
          bad@email.c
          bad@email.com.o
          @email.com
          bad@email
          bad@.com
          !bad@email.com
          bad@email..com
          bad@@email.com
          ba/d@email.com
        ].each do |email|
          author.assign_attributes(email:)
          expect(author).not_to be_valid
          expect(author.errors.full_messages).to include "Email is invalid"
        end
      end

      it "allows various email types" do
        %w[
          good@email.com
          good@email.co.uk
          good@e-m_ail.com
          go_o-d@email.com
          good@email.c_o-m
          good@email.com-
          good@email.comm
        ].each do |email|
          author.assign_attributes(email:)
          expect(author).to be_valid
        end
      end
    end

    describe "username attribute" do
      it "does not allow username longer than 50 characters" do
        author.assign_attributes(username: "x" * 51)
        expect(author).not_to be_valid
        expect(
          author.errors.full_messages
        ).to include "Username is too long (maximum is 50 characters)"
      end

      it "allows usernames with periods, hyphens, and underscores" do
        author.assign_attributes(username: "-s0me_0ne.")
        expect(author).to be_valid
      end

      it "does not allow usernames with other characters" do
        %w[? ! @ # $ % ^ & * ( ) + ~ / \\ ].each do |chr|
          author.assign_attributes(username: "-s0me_0ne.#{chr}")
          expect(author).not_to be_valid
        end
      end
    end
  end

  it "lowers email upon save" do
    email = "Coolio1Nice@email.com"
    author.update!(email:)
    expect(author.email).to eq email.downcase
  end

  describe "#authenticate" do
    let(:password) { "coolio" }
    let!(:a) { create(:author, password:) }

    it "checks the password of the author" do
      expect(a.authenticate(password)).to be_present
      expect(a.authenticate("badpass")).to be false
    end
  end

  describe "#confirm!" do
    context "with confirmed_at" do
      let!(:a) { create(:author, :confirmed) }

      it "does nothing" do
        expect { a.confirm! }.not_to change(a.reload, :confirmed_at)
      end
    end

    context "without confirmed_at" do
      let!(:a) { create(:author, :unconfirmed) }
      let(:now) { Time.current }

      before { allow(Time).to receive(:current).and_return(now) }

      it "fills in the confirmed_at column with the current time" do
        expect { a.confirm! }
          .to change { a.reload.confirmed_at&.strftime("%FT%T.%6N") }
          .from(nil).to(now.strftime("%FT%T.%6N"))
      end
    end
  end

  describe "#confirmed?" do
    context "with confirmed_at" do
      let!(:a) { create(:author, :confirmed) }

      it "returns true" do
        expect(a.confirmed?).to be true
      end
    end

    context "without confirmed_at" do
      let!(:a) { create(:author, :unconfirmed) }

      it "returns false" do
        expect(a.confirmed?).to be false
      end
    end
  end

  describe "#unconfirmed?" do
    context "with confirmed_at" do
      let!(:a) { create(:author, :confirmed) }

      it "returns false" do
        expect(a.unconfirmed?).to be false
      end
    end

    context "without confirmed_at" do
      let!(:a) { create(:author, :unconfirmed) }

      it "returns true" do
        expect(a.unconfirmed?).to be true
      end
    end
  end

  describe "#generate_confirmation_token" do
    context "when unconfirmed" do
      let!(:a) { create(:author, :unconfirmed) }
      let(:token) { a.generate_confirmation_token }

      it "creates a signed id for the user's email confirmation" do
        expect(token).to be_present
        expect(described_class.find_signed(token, purpose: :confirm_email)).to eq a
      end
    end

    context "when confirmed" do
      let!(:a) { create(:author, :confirmed) }
      let(:token) { a.generate_confirmation_token }

      it "does not create a signed id" do
        expect(token).to be_nil
      end
    end
  end

  describe "scopes" do
    let!(:a1) { create(:author, :unconfirmed) }
    let!(:a2) { create(:author, :confirmed) }
    let!(:a3) { create(:author, :unconfirmed) }
    let!(:a4) { create(:author, :unconfirmed) }
    let!(:a5) { create(:author, :confirmed) }

    describe ".confirmed" do
      it "returns the confirmed authors" do
        expect(described_class.confirmed.order(:id).pluck(:id))
          .to eq [a2, a5].map(&:id)
      end
    end

    describe ".unconfirmed" do
      it "returns the unconfirmed authors" do
        expect(described_class.unconfirmed.order(:id).pluck(:id))
          .to eq [a1, a3, a4].map(&:id)
      end
    end
  end
end
