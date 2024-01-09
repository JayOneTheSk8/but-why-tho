require "rails_helper"

RSpec.describe CommentRepost do
  describe "#valid?" do
    context "when reposter is not the author of the comment" do
      let!(:comment) { create(:comment) }
      let!(:comment_repost) { build(:comment_repost, message_id: comment.id) }

      it "is valid" do
        expect(comment_repost).to be_valid
      end
    end

    context "when reposter is the author of the comment" do
      let!(:comment) { create(:comment) }
      let!(:comment_repost) { build(:comment_repost, user: comment.author, message_id: comment.id) }

      it "is not valid" do
        expect(comment_repost).not_to be_valid
      end
    end
  end
end
