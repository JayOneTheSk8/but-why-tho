require "rails_helper"

RSpec.describe Comment do
  it_behaves_like "text must be question(s)", :comment

  describe "#valid?" do
    context "when reply's post is parent's post" do
      let!(:parent_comment) { create(:comment) }
      let(:reply_comment) { build(:comment, :reply, post: parent_comment.post, comment: parent_comment) }

      it "is valid" do
        expect(reply_comment).to be_valid
      end
    end

    context "when reply's post is not parent's post" do
      let!(:parent_comment) { create(:comment) }
      let(:reply_comment) { build(:comment, :reply, comment: parent_comment) }

      it "is not valid" do
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

  describe ".search_comments" do
    let(:substring) { "cool" }

    let(:comment1_text) { "How could one know if that's cool?" }
    let(:comment2_text) { "Cool if I rebut?" }
    let(:comment3_text) { "Not for scool, no?" }

    let(:comment1_repost_count) { 2 }
    let(:comment1_like_count) { 5 }
    let(:comment1_comment_count) { 4 }

    let(:comment2_repost_count) { 1 }
    let(:comment2_like_count) { 3 }
    let(:comment2_comment_count) { 7 }

    let(:comment3_repost_count) { 7 }
    let(:comment3_like_count) { 6 }
    let(:comment3_comment_count) { 2 }

    # Rating 20
    let!(:comment1) do
      create(
        :comment,
        :liked,
        :reposted,
        :reply,
        :replied,
        text: comment1_text,
        repost_count: comment1_repost_count,
        like_count: comment1_like_count,
        reply_count: comment1_comment_count
      )
    end
    # Rating 16
    let!(:comment2) do
      create(
        :comment,
        :liked,
        :reposted,
        :replied,
        text: comment2_text,
        repost_count: comment2_repost_count,
        like_count: comment2_like_count,
        reply_count: comment2_comment_count
      )
    end
    # Rating 35
    let!(:comment3) do
      create(
        :comment,
        :liked,
        :reposted,
        :replied,
        text: comment3_text,
        repost_count: comment3_repost_count,
        like_count: comment3_like_count,
        reply_count: comment3_comment_count
      )
    end

    it "finds posts whose texts contain the passed substring; sorting by popularity" do
      expect(described_class.search_comments(substring))
        .to eq(
          [
            {
              id: comment3.id,
              text: comment3.text,
              created_at: comment3.created_at,
              post_type: "Comment",
              like_count: comment3_like_count,
              repost_count: comment3_repost_count,
              comment_count: comment3_comment_count,
              post_date: comment3.created_at,
              user_liked: false,
              user_reposted: false,
              user_followed: false,
              rating: 35,
              replying_to: [comment3.post.author.username],
              author: {
                id: comment3.author_id,
                username: comment3.author.username,
                display_name: comment3.author.display_name
              }
            },
            {
              id: comment1.id,
              text: comment1.text,
              created_at: comment1.created_at,
              post_type: "Comment",
              like_count: comment1_like_count,
              repost_count: comment1_repost_count,
              comment_count: comment1_comment_count,
              post_date: comment1.created_at,
              user_liked: false,
              user_reposted: false,
              user_followed: false,
              rating: 20,
              replying_to: [comment1.parent.author.username, comment1.post.author.username],
              author: {
                id: comment1.author_id,
                username: comment1.author.username,
                display_name: comment1.author.display_name
              }
            },
            {
              id: comment2.id,
              text: comment2.text,
              created_at: comment2.created_at,
              post_type: "Comment",
              like_count: comment2_like_count,
              repost_count: comment2_repost_count,
              comment_count: comment2_comment_count,
              post_date: comment2.created_at,
              user_liked: false,
              user_reposted: false,
              user_followed: false,
              rating: 16,
              replying_to: [comment2.post.author.username],
              author: {
                id: comment2.author_id,
                username: comment2.author.username,
                display_name: comment2.author.display_name
              }
            }
          ]
        )
    end

    context "with limit" do
      it "returns a certain amount of posts" do
        expect(described_class.search_comments(substring, limit: 2))
          .to eq(
            [
              {
                id: comment3.id,
                text: comment3.text,
                created_at: comment3.created_at,
                post_type: "Comment",
                like_count: comment3_like_count,
                repost_count: comment3_repost_count,
                comment_count: comment3_comment_count,
                post_date: comment3.created_at,
                user_liked: false,
                user_reposted: false,
                user_followed: false,
                rating: 35,
                replying_to: [comment3.post.author.username],
                author: {
                  id: comment3.author_id,
                  username: comment3.author.username,
                  display_name: comment3.author.display_name
                }
              },
              {
                id: comment1.id,
                text: comment1.text,
                created_at: comment1.created_at,
                post_type: "Comment",
                like_count: comment1_like_count,
                repost_count: comment1_repost_count,
                comment_count: comment1_comment_count,
                post_date: comment1.created_at,
                user_liked: false,
                user_reposted: false,
                user_followed: false,
                rating: 20,
                replying_to: [comment1.parent.author.username, comment1.post.author.username],
                author: {
                  id: comment1.author_id,
                  username: comment1.author.username,
                  display_name: comment1.author.display_name
                }
              }
            ]
          )
      end
    end

    context "with current user" do
      let!(:current_user) { create(:user) }

      before do
        create(:follow, followee: comment2.author, follower: current_user)
        create(:comment_like, message_id: comment1.id, user: current_user)
        create(:comment_repost, message_id: comment3.id, user: current_user)
      end

      it "returns whether or not the current user liked or reposted the post or follows the author" do
        expect(described_class.search_comments(substring, current_user:))
          .to eq(
            [
              {
                id: comment3.id,
                text: comment3.text,
                created_at: comment3.created_at,
                post_type: "Comment",
                like_count: comment3_like_count,
                repost_count: comment3_repost_count + 1,
                comment_count: comment3_comment_count,
                post_date: comment3.created_at,
                user_liked: false,
                user_reposted: true,
                user_followed: false,
                rating: 35 + 3,
                replying_to: [comment3.post.author.username],
                author: {
                  id: comment3.author_id,
                  username: comment3.author.username,
                  display_name: comment3.author.display_name
                }
              },
              {
                id: comment1.id,
                text: comment1.text,
                created_at: comment1.created_at,
                post_type: "Comment",
                like_count: comment1_like_count + 1,
                repost_count: comment1_repost_count,
                comment_count: comment1_comment_count,
                post_date: comment1.created_at,
                user_liked: true,
                user_reposted: false,
                user_followed: false,
                rating: 20 + 2,
                replying_to: [comment1.parent.author.username, comment1.post.author.username],
                author: {
                  id: comment1.author_id,
                  username: comment1.author.username,
                  display_name: comment1.author.display_name
                }
              },
              {
                id: comment2.id,
                text: comment2.text,
                created_at: comment2.created_at,
                post_type: "Comment",
                like_count: comment2_like_count,
                repost_count: comment2_repost_count,
                comment_count: comment2_comment_count,
                post_date: comment2.created_at,
                user_liked: false,
                user_reposted: false,
                user_followed: true,
                rating: 16,
                replying_to: [comment2.post.author.username],
                author: {
                  id: comment2.author_id,
                  username: comment2.author.username,
                  display_name: comment2.author.display_name
                }
              }
            ]
          )
      end
    end
  end
end
