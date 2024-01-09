require "rails_helper"

RSpec.describe PostRepost do
  describe "#valid?" do
    context "when reposter is not the author of the post" do
      let!(:post) { create(:post) }
      let!(:post_repost) { build(:post_repost, message_id: post.id) }

      it "is valid" do
        expect(post_repost).to be_valid
      end
    end

    context "when reposter is the author of the post" do
      let!(:post) { create(:post) }
      let!(:post_repost) { build(:post_repost, user: post.author, message_id: post.id) }

      it "is not valid" do
        expect(post_repost).not_to be_valid
      end
    end
  end
end
