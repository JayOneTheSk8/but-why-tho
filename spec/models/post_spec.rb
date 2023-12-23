require "rails_helper"

RSpec.describe Post do
  let(:post) { build(:post) }

  describe "valid?" do
    %i[text].each do |attr|
      it "is invalid with a nil #{attr}" do
        post.assign_attributes(attr => nil)
        expect(post).not_to be_valid
        expect(
          post.errors.full_messages.map(&:downcase)
        ).to include "#{attr} can't be blank"
      end
    end

    it "does not allow for text longer than 200 characters" do
      post.assign_attributes(text: "#{'n' * 200}?")
      expect(post).not_to be_valid
      expect(
        post.errors.full_messages
      ).to include "Text is too long (maximum is 200 characters)"
    end

    it "requires the text to be a question" do
      post.assign_attributes(text: "I don't think this should be allowed")
      expect(post).not_to be_valid
      expect(
        post.errors.full_messages
      ).to include "Text must only have questions"
    end

    it "allows multiple questions" do
      post.assign_attributes(text: "Are there wild things out there? Should we be careful?")
      expect(post).to be_valid
    end

    it "does not allow for sentences or exclamations" do
      [
        "Wow, things are great!",
        "Wow, things are great¡",
        "There are wild things out there."
      ].each do |sentence|
        post.assign_attributes(text: "#{sentence} So are you in?")
        expect(post).not_to be_valid
        expect(
          post.errors.full_messages
        ).to include "Text must only have questions"
      end
    end
  end
end
