require "rails_helper"

RSpec.describe "Search Requests" do
  let(:substring) { "cool" }

  # Rating 4
  let(:user1_follower_count) { 1 }
  let(:user1_followed_user_count) { 1 }
  let!(:user1) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      username: "#{substring}1",
      follower_count: user1_follower_count,
      followed_user_count: user1_followed_user_count
    )
  end
  # Rating 11
  let(:user2_follower_count) { 3 }
  let(:user2_followed_user_count) { 2 }
  let!(:user2) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      username: "#{substring}2",
      follower_count: user2_follower_count,
      followed_user_count: user2_followed_user_count
    )
  end
  # Rating 13
  let(:user3_follower_count) { 4 }
  let(:user3_followed_user_count) { 1 }
  let!(:user3) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      username: "#{substring}3",
      follower_count: user3_follower_count,
      followed_user_count: user3_followed_user_count
    )
  end
  # Rating 17
  let(:user4_follower_count) { 5 }
  let(:user4_followed_user_count) { 2 }
  let!(:user4) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      username: "#{substring}4",
      follower_count: user4_follower_count,
      followed_user_count: user4_followed_user_count
    )
  end
  # Rating 8
  let(:user5_follower_count) { 2 }
  let(:user5_followed_user_count) { 2 }
  let!(:user5) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      username: "#{substring}5",
      follower_count: user5_follower_count,
      followed_user_count: user5_followed_user_count
    )
  end
  # Rating 10
  let(:user6_follower_count) { 2 }
  let(:user6_followed_user_count) { 4 }
  let!(:user6) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      display_name: "#{substring}6",
      follower_count: user6_follower_count,
      followed_user_count: user6_followed_user_count
    )
  end
  # Rating 5
  let(:user7_follower_count) { 1 }
  let(:user7_followed_user_count) { 2 }
  let!(:user7) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      display_name: "#{substring}7",
      follower_count: user7_follower_count,
      followed_user_count: user7_followed_user_count
    )
  end
  # Rating 7
  let(:user8_follower_count) { 2 }
  let(:user8_followed_user_count) { 1 }
  let!(:user8) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      display_name: "#{substring}8",
      follower_count: user8_follower_count,
      followed_user_count: user8_followed_user_count
    )
  end
  # Rating 17
  let(:user9_follower_count) { 4 }
  let(:user9_followed_user_count) { 5 }
  let!(:user9) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      display_name: "#{substring}9",
      follower_count: user9_follower_count,
      followed_user_count: user9_followed_user_count
    )
  end
  # Rating 8
  let(:user10_follower_count) { 1 }
  let(:user10_followed_user_count) { 5 }
  let!(:user10) do
    create(
      :user,
      :with_followed_users,
      :with_followers,
      display_name: "#{substring}10",
      follower_count: user10_follower_count,
      followed_user_count: user10_followed_user_count
    )
  end

  let(:post1_like_count) { 5 }
  let(:post1_repost_count) { 2 }
  let(:post1_comment_count) { 4 }

  let(:post2_like_count) { 3 }
  let(:post2_repost_count) { 1 }
  let(:post2_comment_count) { 7 }

  let(:post3_like_count) { 6 }
  let(:post3_repost_count) { 7 }
  let(:post3_comment_count) { 2 }

  let(:post4_like_count) { 9 }
  let(:post4_repost_count) { 4 }
  let(:post4_comment_count) { 1 }

  # Rating 20
  let!(:post1) do
    create(
      :post,
      :liked,
      :reposted,
      :commented_with_replies,
      text: "#{substring}?",
      like_count: post1_like_count,
      repost_count: post1_repost_count,
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
      text: "#{substring}?",
      like_count: post2_like_count,
      repost_count: post2_repost_count,
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
      text: "#{substring}?",
      like_count: post3_like_count,
      repost_count: post3_repost_count,
      replied_comment_count: post3_comment_count
    )
  end
  # Rating 31
  let!(:post4) do
    create(
      :post,
      :liked,
      :reposted,
      :commented_with_replies,
      text: "#{substring}?",
      like_count: post4_like_count,
      repost_count: post4_repost_count,
      replied_comment_count: post4_comment_count
    )
  end

  let(:comment1_like_count) { 5 }
  let(:comment1_repost_count) { 2 }
  let(:comment1_comment_count) { 4 }

  let(:comment2_like_count) { 3 }
  let(:comment2_repost_count) { 1 }
  let(:comment2_comment_count) { 7 }

  let(:comment3_like_count) { 6 }
  let(:comment3_repost_count) { 7 }
  let(:comment3_comment_count) { 2 }

  let(:comment4_like_count) { 9 }
  let(:comment4_repost_count) { 4 }
  let(:comment4_comment_count) { 1 }

  # Rating 20
  let!(:comment1) do
    create(
      :comment,
      :liked,
      :reposted,
      :replied,
      text: "#{substring}?",
      like_count: comment1_like_count,
      repost_count: comment1_repost_count,
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
      text: "#{substring}?",
      like_count: comment2_like_count,
      repost_count: comment2_repost_count,
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
      text: "#{substring}?",
      like_count: comment3_like_count,
      repost_count: comment3_repost_count,
      reply_count: comment3_comment_count
    )
  end
  # Rating 31
  let!(:comment4) do
    create(
      :comment,
      :liked,
      :reposted,
      :replied,
      text: "#{substring}?",
      like_count: comment4_like_count,
      repost_count: comment4_repost_count,
      reply_count: comment4_comment_count
    )
  end

  let(:search_params) { { search: { text: substring } } }

  before do
    create_list(:user, 10)
    create_list(:post, 10)
    create_list(:comment, 10)
  end

  describe "/search/quick" do
    it "returns the top 6 found popular/active users" do
      get "/search/quick", params: search_params
      expect(response.parsed_body).to eq(
        {
          "users" => [
            {
              "id" => user9.id,
              "username" => user9.username,
              "display_name" => user9.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user9_follower_count,
              "followed_user_count" => user9_followed_user_count,
              "user_rating" => 17
            },
            {
              "id" => user4.id,
              "username" => user4.username,
              "display_name" => user4.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user4_follower_count,
              "followed_user_count" => user4_followed_user_count,
              "user_rating" => 17
            },
            {
              "id" => user3.id,
              "username" => user3.username,
              "display_name" => user3.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user3_follower_count,
              "followed_user_count" => user3_followed_user_count,
              "user_rating" => 13
            },
            {
              "id" => user2.id,
              "username" => user2.username,
              "display_name" => user2.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user2_follower_count,
              "followed_user_count" => user2_followed_user_count,
              "user_rating" => 11
            },
            {
              "id" => user6.id,
              "username" => user6.username,
              "display_name" => user6.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user6_follower_count,
              "followed_user_count" => user6_followed_user_count,
              "user_rating" => 10
            },
            {
              "id" => user10.id,
              "username" => user10.username,
              "display_name" => user10.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user10_follower_count,
              "followed_user_count" => user10_followed_user_count,
              "user_rating" => 8
            }
          ]
        }
      )
    end
  end

  describe "/search/top" do
    it "returns the top 3 found users, posts, comments" do
      get "/search/top", params: search_params
      expect(response.parsed_body).to eq(
        {
          "users" => [
            {
              "id" => user9.id,
              "username" => user9.username,
              "display_name" => user9.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user9_follower_count,
              "followed_user_count" => user9_followed_user_count,
              "user_rating" => 17
            },
            {
              "id" => user4.id,
              "username" => user4.username,
              "display_name" => user4.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user4_follower_count,
              "followed_user_count" => user4_followed_user_count,
              "user_rating" => 17
            },
            {
              "id" => user3.id,
              "username" => user3.username,
              "display_name" => user3.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user3_follower_count,
              "followed_user_count" => user3_followed_user_count,
              "user_rating" => 13
            }
          ],
          "posts" => [
            {
              "id" => post3.id,
              "text" => post3.text,
              "created_at" => post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Post",
              "like_count" => post3_like_count,
              "repost_count" => post3_repost_count,
              "comment_count" => post3_comment_count,
              "post_date" => post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 35,
              "replying_to" => nil,
              "author" => {
                "id" => post3.author_id,
                "username" => post3.author.username,
                "display_name" => post3.author.display_name
              }
            },
            {
              "id" => post4.id,
              "text" => post4.text,
              "created_at" => post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Post",
              "like_count" => post4_like_count,
              "repost_count" => post4_repost_count,
              "comment_count" => post4_comment_count,
              "post_date" => post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 31,
              "replying_to" => nil,
              "author" => {
                "id" => post4.author_id,
                "username" => post4.author.username,
                "display_name" => post4.author.display_name
              }
            },
            {
              "id" => post1.id,
              "text" => post1.text,
              "created_at" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Post",
              "like_count" => post1_like_count,
              "repost_count" => post1_repost_count,
              "comment_count" => post1_comment_count,
              "post_date" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 20,
              "replying_to" => nil,
              "author" => {
                "id" => post1.author_id,
                "username" => post1.author.username,
                "display_name" => post1.author.display_name
              }
            }
          ],
          "comments" => [
            {
              "id" => comment3.id,
              "text" => comment3.text,
              "created_at" => comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment3_like_count,
              "repost_count" => comment3_repost_count,
              "comment_count" => comment3_comment_count,
              "post_date" => comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 35,
              "replying_to" => [comment3.post.author.username],
              "author" => {
                "id" => comment3.author_id,
                "username" => comment3.author.username,
                "display_name" => comment3.author.display_name
              }
            },
            {
              "id" => comment4.id,
              "text" => comment4.text,
              "created_at" => comment4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment4_like_count,
              "repost_count" => comment4_repost_count,
              "comment_count" => comment4_comment_count,
              "post_date" => comment4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 31,
              "replying_to" => [comment4.post.author.username],
              "author" => {
                "id" => comment4.author_id,
                "username" => comment4.author.username,
                "display_name" => comment4.author.display_name
              }
            },
            {
              "id" => comment1.id,
              "text" => comment1.text,
              "created_at" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment1_like_count,
              "repost_count" => comment1_repost_count,
              "comment_count" => comment1_comment_count,
              "post_date" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 20,
              "replying_to" => [comment1.post.author.username],
              "author" => {
                "id" => comment1.author_id,
                "username" => comment1.author.username,
                "display_name" => comment1.author.display_name
              }
            }
          ]
        }
      )
    end
  end

  # There is a limit of 100 for these but I don't think we need to test this,
  # only that we get "all" the found users. No one is ever going to go through
  # 100 users

  describe "/search/users" do
    it "returns the found users" do
      get "/search/users", params: search_params
      expect(response.parsed_body).to eq(
        {
          "users" => [
            {
              "id" => user9.id,
              "username" => user9.username,
              "display_name" => user9.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user9_follower_count,
              "followed_user_count" => user9_followed_user_count,
              "user_rating" => 17
            },
            {
              "id" => user4.id,
              "username" => user4.username,
              "display_name" => user4.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user4_follower_count,
              "followed_user_count" => user4_followed_user_count,
              "user_rating" => 17
            },
            {
              "id" => user3.id,
              "username" => user3.username,
              "display_name" => user3.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user3_follower_count,
              "followed_user_count" => user3_followed_user_count,
              "user_rating" => 13
            },
            {
              "id" => user2.id,
              "username" => user2.username,
              "display_name" => user2.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user2_follower_count,
              "followed_user_count" => user2_followed_user_count,
              "user_rating" => 11
            },
            {
              "id" => user6.id,
              "username" => user6.username,
              "display_name" => user6.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user6_follower_count,
              "followed_user_count" => user6_followed_user_count,
              "user_rating" => 10
            },
            {
              "id" => user10.id,
              "username" => user10.username,
              "display_name" => user10.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user10_follower_count,
              "followed_user_count" => user10_followed_user_count,
              "user_rating" => 8
            },
            {
              "id" => user5.id,
              "username" => user5.username,
              "display_name" => user5.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user5_follower_count,
              "followed_user_count" => user5_followed_user_count,
              "user_rating" => 8
            },
            {
              "id" => user8.id,
              "username" => user8.username,
              "display_name" => user8.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user8_follower_count,
              "followed_user_count" => user8_followed_user_count,
              "user_rating" => 7
            },
            {
              "id" => user7.id,
              "username" => user7.username,
              "display_name" => user7.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user7_follower_count,
              "followed_user_count" => user7_followed_user_count,
              "user_rating" => 5
            },
            {
              "id" => user1.id,
              "username" => user1.username,
              "display_name" => user1.display_name,
              "current_user_following" => false,
              "following_current_user" => false,
              "follower_count" => user1_follower_count,
              "followed_user_count" => user1_followed_user_count,
              "user_rating" => 4
            }
          ]
        }
      )
    end
  end

  describe "/search/posts" do
    it "returns the found posts" do
      get "/search/posts", params: search_params
      expect(response.parsed_body).to eq(
        "posts" => [
          {
            "id" => post3.id,
            "text" => post3.text,
            "created_at" => post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_type" => "Post",
            "like_count" => post3_like_count,
            "repost_count" => post3_repost_count,
            "comment_count" => post3_comment_count,
            "post_date" => post3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "user_liked" => false,
            "user_reposted" => false,
            "user_followed" => false,
            "rating" => 35,
            "replying_to" => nil,
            "author" => {
              "id" => post3.author_id,
              "username" => post3.author.username,
              "display_name" => post3.author.display_name
            }
          },
          {
            "id" => post4.id,
            "text" => post4.text,
            "created_at" => post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_type" => "Post",
            "like_count" => post4_like_count,
            "repost_count" => post4_repost_count,
            "comment_count" => post4_comment_count,
            "post_date" => post4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "user_liked" => false,
            "user_reposted" => false,
            "user_followed" => false,
            "rating" => 31,
            "replying_to" => nil,
            "author" => {
              "id" => post4.author_id,
              "username" => post4.author.username,
              "display_name" => post4.author.display_name
            }
          },
          {
            "id" => post1.id,
            "text" => post1.text,
            "created_at" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_type" => "Post",
            "like_count" => post1_like_count,
            "repost_count" => post1_repost_count,
            "comment_count" => post1_comment_count,
            "post_date" => post1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "user_liked" => false,
            "user_reposted" => false,
            "user_followed" => false,
            "rating" => 20,
            "replying_to" => nil,
            "author" => {
              "id" => post1.author_id,
              "username" => post1.author.username,
              "display_name" => post1.author.display_name
            }
          },
          {
            "id" => post2.id,
            "text" => post2.text,
            "created_at" => post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "post_type" => "Post",
            "like_count" => post2_like_count,
            "repost_count" => post2_repost_count,
            "comment_count" => post2_comment_count,
            "post_date" => post2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
            "user_liked" => false,
            "user_reposted" => false,
            "user_followed" => false,
            "rating" => 16,
            "replying_to" => nil,
            "author" => {
              "id" => post2.author_id,
              "username" => post2.author.username,
              "display_name" => post2.author.display_name
            }
          }
        ]
      )
    end
  end

  describe "/search/comments" do
    it "returns the found comments" do
      get "/search/comments", params: search_params
      expect(response.parsed_body).to eq(
        {
          "comments" => [
            {
              "id" => comment3.id,
              "text" => comment3.text,
              "created_at" => comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment3_like_count,
              "repost_count" => comment3_repost_count,
              "comment_count" => comment3_comment_count,
              "post_date" => comment3.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 35,
              "replying_to" => [comment3.post.author.username],
              "author" => {
                "id" => comment3.author_id,
                "username" => comment3.author.username,
                "display_name" => comment3.author.display_name
              }
            },
            {
              "id" => comment4.id,
              "text" => comment4.text,
              "created_at" => comment4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment4_like_count,
              "repost_count" => comment4_repost_count,
              "comment_count" => comment4_comment_count,
              "post_date" => comment4.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 31,
              "replying_to" => [comment4.post.author.username],
              "author" => {
                "id" => comment4.author_id,
                "username" => comment4.author.username,
                "display_name" => comment4.author.display_name
              }
            },
            {
              "id" => comment1.id,
              "text" => comment1.text,
              "created_at" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment1_like_count,
              "repost_count" => comment1_repost_count,
              "comment_count" => comment1_comment_count,
              "post_date" => comment1.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 20,
              "replying_to" => [comment1.post.author.username],
              "author" => {
                "id" => comment1.author_id,
                "username" => comment1.author.username,
                "display_name" => comment1.author.display_name
              }
            },
            {
              "id" => comment2.id,
              "text" => comment2.text,
              "created_at" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "post_type" => "Comment",
              "like_count" => comment2_like_count,
              "repost_count" => comment2_repost_count,
              "comment_count" => comment2_comment_count,
              "post_date" => comment2.created_at.strftime("%Y-%m-%dT%T.%LZ"),
              "user_liked" => false,
              "user_reposted" => false,
              "user_followed" => false,
              "rating" => 16,
              "replying_to" => [comment2.post.author.username],
              "author" => {
                "id" => comment2.author_id,
                "username" => comment2.author.username,
                "display_name" => comment2.author.display_name
              }
            }
          ]
        }
      )
    end
  end
end
