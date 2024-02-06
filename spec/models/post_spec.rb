require "rails_helper"

RSpec.describe Post do
  it_behaves_like "text must be question(s)", :post

  describe ".search_posts" do
    let(:substring) { "cool" }

    let(:post1_text) { "How could one know if that's cool?" }
    let(:post2_text) { "Cool if I rebut?" }
    let(:post3_text) { "Not for scool, no?" }

    let(:post1_repost_count) { 2 }
    let(:post1_like_count) { 5 }
    let(:post1_comment_count) { 4 }

    let(:post2_repost_count) { 1 }
    let(:post2_like_count) { 3 }
    let(:post2_comment_count) { 7 }

    let(:post3_repost_count) { 7 }
    let(:post3_like_count) { 6 }
    let(:post3_comment_count) { 2 }

    # Rating 20
    let!(:post1) do
      create(
        :post,
        :liked,
        :reposted,
        :commented_with_replies,
        text: post1_text,
        repost_count: post1_repost_count,
        like_count: post1_like_count,
        replied_comment_count: post1_comment_count
      )
    end
    # Rating 16
    let!(:post2) do
      create(
        :post,
        :liked,
        :reposted,
        :commented_with_replies,
        text: post2_text,
        repost_count: post2_repost_count,
        like_count: post2_like_count,
        replied_comment_count: post2_comment_count
      )
    end
    # Rating 35
    let!(:post3) do
      create(
        :post,
        :liked,
        :reposted,
        :commented_with_replies,
        text: post3_text,
        repost_count: post3_repost_count,
        like_count: post3_like_count,
        replied_comment_count: post3_comment_count
      )
    end

    it "finds posts whose texts contain the passed substring; sorting by popularity" do
      expect(described_class.search_posts(substring))
        .to eq(
          [
            {
              id: post3.id,
              text: post3.text,
              created_at: post3.created_at,
              post_type: "Post",
              like_count: post3_like_count,
              repost_count: post3_repost_count,
              comment_count: post3_comment_count,
              post_date: post3.created_at,
              user_liked: false,
              user_reposted: false,
              user_followed: false,
              rating: 35,
              replying_to: nil,
              author: {
                id: post3.author_id,
                username: post3.author.username,
                display_name: post3.author.display_name
              }
            },
            {
              id: post1.id,
              text: post1.text,
              created_at: post1.created_at,
              post_type: "Post",
              like_count: post1_like_count,
              repost_count: post1_repost_count,
              comment_count: post1_comment_count,
              post_date: post1.created_at,
              user_liked: false,
              user_reposted: false,
              user_followed: false,
              rating: 20,
              replying_to: nil,
              author: {
                id: post1.author_id,
                username: post1.author.username,
                display_name: post1.author.display_name
              }
            },
            {
              id: post2.id,
              text: post2.text,
              created_at: post2.created_at,
              post_type: "Post",
              like_count: post2_like_count,
              repost_count: post2_repost_count,
              comment_count: post2_comment_count,
              post_date: post2.created_at,
              user_liked: false,
              user_reposted: false,
              user_followed: false,
              rating: 16,
              replying_to: nil,
              author: {
                id: post2.author_id,
                username: post2.author.username,
                display_name: post2.author.display_name
              }
            }
          ]
        )
    end

    context "with limit" do
      it "returns a certain amount of posts" do
        expect(described_class.search_posts(substring, limit: 2))
          .to eq(
            [
              {
                id: post3.id,
                text: post3.text,
                created_at: post3.created_at,
                post_type: "Post",
                like_count: post3_like_count,
                repost_count: post3_repost_count,
                comment_count: post3_comment_count,
                post_date: post3.created_at,
                user_liked: false,
                user_reposted: false,
                user_followed: false,
                rating: 35,
                replying_to: nil,
                author: {
                  id: post3.author_id,
                  username: post3.author.username,
                  display_name: post3.author.display_name
                }
              },
              {
                id: post1.id,
                text: post1.text,
                created_at: post1.created_at,
                post_type: "Post",
                like_count: post1_like_count,
                repost_count: post1_repost_count,
                comment_count: post1_comment_count,
                post_date: post1.created_at,
                user_liked: false,
                user_reposted: false,
                user_followed: false,
                rating: 20,
                replying_to: nil,
                author: {
                  id: post1.author_id,
                  username: post1.author.username,
                  display_name: post1.author.display_name
                }
              }
            ]
          )
      end
    end

    context "with current user" do
      let!(:current_user) { create(:user) }

      before do
        create(:follow, followee: post2.author, follower: current_user)
        create(:post_like, message_id: post1.id, user: current_user)
        create(:post_repost, message_id: post3.id, user: current_user)
      end

      it "returns whether or not the current user liked or reposted the post or follows the author" do
        expect(described_class.search_posts(substring, current_user:))
          .to eq(
            [
              {
                id: post3.id,
                text: post3.text,
                created_at: post3.created_at,
                post_type: "Post",
                like_count: post3_like_count,
                repost_count: post3_repost_count + 1,
                comment_count: post3_comment_count,
                post_date: post3.created_at,
                user_liked: false,
                user_reposted: true,
                user_followed: false,
                rating: 35 + 3,
                replying_to: nil,
                author: {
                  id: post3.author_id,
                  username: post3.author.username,
                  display_name: post3.author.display_name
                }
              },
              {
                id: post1.id,
                text: post1.text,
                created_at: post1.created_at,
                post_type: "Post",
                like_count: post1_like_count + 1,
                repost_count: post1_repost_count,
                comment_count: post1_comment_count,
                post_date: post1.created_at,
                user_liked: true,
                user_reposted: false,
                user_followed: false,
                rating: 20 + 2,
                replying_to: nil,
                author: {
                  id: post1.author_id,
                  username: post1.author.username,
                  display_name: post1.author.display_name
                }
              },
              {
                id: post2.id,
                text: post2.text,
                created_at: post2.created_at,
                post_type: "Post",
                like_count: post2_like_count,
                repost_count: post2_repost_count,
                comment_count: post2_comment_count,
                post_date: post2.created_at,
                user_liked: false,
                user_reposted: false,
                user_followed: true,
                rating: 16,
                replying_to: nil,
                author: {
                  id: post2.author_id,
                  username: post2.author.username,
                  display_name: post2.author.display_name
                }
              }
            ]
          )
      end
    end
  end
end
