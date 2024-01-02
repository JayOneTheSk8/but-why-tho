require "rails_helper"

RSpec.describe Comment do
  it_behaves_like "text must be question(s)", :comment

  describe "#valid?" do
    context "when reply's post matches parent's post" do
      let!(:parent_comment) { create(:comment) }
      let(:reply_comment) { build(:comment, :reply, post: parent_comment.post, comment: parent_comment) }

      it "is valid" do
        expect(reply_comment).to be_valid
      end
    end

    context "when reply's post does not parent's post" do
      let!(:parent_comment) { create(:comment) }
      let(:reply_comment) { build(:comment, :reply, comment: parent_comment) }

      it "is valid" do
        expect(reply_comment).not_to be_valid
      end
    end
  end

  describe "scopes" do
    before do
      pc1 = create(:comment)
      create(:comment, :reply, post: pc1.post, comment: pc1)
      pc2 = create(:comment)
      create(:comment)
      create(:comment, :reply, post: pc2.post, comment: pc2)
      create(:comment, :reply, post: pc2.post, comment: pc2)
      create(:comment)
    end

    describe ".parents" do
      it "returns the parent comments" do
        expect(described_class.parents.length).to eq 4
      end
    end

    describe ".replies" do
      it "returns the reply comments" do
        expect(described_class.replies.length).to eq 3
      end
    end
  end
end
