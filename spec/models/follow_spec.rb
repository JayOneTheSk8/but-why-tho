require "rails_helper"

RSpec.describe Follow do
  describe "#valid?" do
    context "when follower and followee are different" do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:follow) { build(:follow, followee_id: user1.id, follower_id: user2.id) }

      it "is valid" do
        expect(follow).to be_valid
      end
    end

    context "when follower and followee are the same" do
      let!(:user) { create(:user) }
      let!(:follow) { build(:follow, followee_id: user.id, follower_id: user.id) }

      it "is not valid" do
        expect(follow).not_to be_valid
      end
    end
  end
end
