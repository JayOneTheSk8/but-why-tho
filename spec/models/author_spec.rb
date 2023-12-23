require "rails_helper"

RSpec.describe Author do
  let(:author) { build(:author) }

  describe "valid?" do
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

    it "does not allow for malformed email addresses" do
      [
        "bademail.com",
        "bad@email.c",
        "bad@email.com.o",
        "@email.com",
        "bad@email",
        "bad@.com",
        "!bad@email.com",
        "bad@email..com",
        "bad@@email.com",
        "ba/d@email.com"
      ].each do |email|
        author.assign_attributes(email:)
        expect(author).not_to be_valid
        expect(author.errors.full_messages).to include "Email is invalid"
      end
    end

    it "allows various email types" do
      [
        "good@email.com",
        "good@email.co.uk",
        "good@e-m_ail.com",
        "go_o-d@email.com",
        "good@email.c_o-m",
        "good@email.com-", # not worth excluding in my opinion
        "good@email.comm"
      ].each do |email|
        author.assign_attributes(email:)
        expect(author).to be_valid
      end
    end

    it "does not allow username longer than 50 characters" do
      author.assign_attributes(username: "x" * 51)
      expect(author).not_to be_valid
      expect(
        author.errors.full_messages
      ).to include "Username is too long (maximum is 50 characters)"
    end
  end

  it "lowers email upon save" do
    email = "Coolio1Nice@email.com"
    author.update!(email:)
    expect(author.email).to eq email.downcase
  end
end
