# Why? (Server)

`Why` is a platform for posting questions and asking more. Users can create posts and comments as long as they're all questions, encouraging deeper thought. Users can also follow each other and like and repost posts and comments. Posts and highly reposted comments are aggregated onto the front page. For a currated list, a user can view a front page their followed users.

Installation
===================

Requires `ruby-3.2.2` and [postgresql](https://www.postgresql.org/download/)

```
bundle install
bin/rails db:migrate
```

### Run Server

```
bin/rails s
```

### Lint (via Rubocop)
```
bin/rubocop
```

### Run Test Specs
```
bin/rspec
```

API Specs
===================

## Authentication

### POST /sign_up
Creates a new `User` and signs them in.

#### Request
```ruby
{
  "user": {
    "username": <string> 
    "display_name": <string>
    "email": <string>
    "password": <string>
    "password_confirmation": <string> # optional
  }
}
```

#### Response
```ruby
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
}
```

### POST /sign_in
Signs a `User` in.

#### Request
```ruby
{
  "user": {
    "login": <string> # Username or email or user
    "password": <string>
  }
}
```

#### Response
```ruby
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
}
```

### GET /sign_out
Signs the `User` out.

#### Response
200 OK


### GET /sessions
Returns the current logged in `User`.

#### Response
```ruby
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
}
```

## Users

### GET /users/:username
Get the data of the `User`.

#### Response
```ruby
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
  "following_count": <int>
  "follower_count": <int>
}
```

### PUT /users/:id
Edits the `User`.

```ruby
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
  "following_count": <int>
  "follower_count": <int>
}
```

## Posts

### GET /posts
Gets all `Post`s by lastest creation date.

#### Response
```ruby
[
  {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "current_user_following": <boolean>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
    "comments": [
      {
        "id": <bigint>
        "text": <string>
        "created_at": <datetime>
        "reply_count": <int>
        "author": {
          "id": <bigint>
          "username": <string>
          "display_name": <string>
        }
      }
      ...
    ]
  }
  ...
]
```

### GET /posts/:id
Gets the data of the `Post`.

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "comment_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "comments": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### POST /posts
Creates a new `Post`.

#### Request
```ruby
{
  "post": {
    "text": <string>
  }
}
```

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "comment_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "comments": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### PUT /posts/:id
Updates a `Post`'s text.

#### Request
```ruby
{
  "post": {
    "text": <string>
  }
}
```

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "comment_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "comments": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### DELETE /posts/:id
Deletes a `Post` and its associated comments

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "comment_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "comments": []
}
```

### GET /users/:user_id/posts
Gets the `User`'s created `Post`s.

#### Response
```ruby
[
  {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "current_user_following": false
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
    "comments": [
      {
        "id": <bigint>
        "text": <string>
        "created_at": <datetime>
        "reply_count": <int>
        "author": {
          "id": <bigint>
          "username": <string>
          "display_name": <string>
        }
      }
      ...
    ]
  }
  ...
]
```

### GET /users/:user_id/linked_posts
Gets all `User`'s created `Post`s and reposted `Post`s and `Comment`s

#### Response
```ruby
{
  "user": {
    "username": <string>
    "display_name": <string>
  }
  "posts": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "post_type": <CommentRepost|PostRepost|Post>
      "like_count": <int>
      "repost_count": <int>
      "comment_count": <int>
      "post_date": <datetime> # datetime of post creation or repost
      "reposted_by": <string> # display name of reposter; optional
      "user_liked": <boolean> # current user liked
      "user_reposted": <boolean> # current user reposted
      "user_followed": <boolean> # current user following author
      "replying_to": <string[]> # usernames of parent comment and post author; optional
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### GET /posts/front_page
Gets the most popular `Post`s and reposted `Comment`s by date and popularity.

#### Response
```ruby
{
  "posts": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "post_type": <CommentRepost||Post>
      "like_count": <int>
      "repost_count": <int>
      "comment_count": <int>
      "post_date": <datetime>
      "user_liked": <boolean>
      "user_reposted": <boolean>
      "user_followed": <boolean>
      "rating": <int> # comment/post's popularity
      "replying_to": <string[]>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### GET /front_page_following
Gets the most popular posts and reposted comments by date and popularity; filtered by the current `User`'s following list. Includes the `User`'s posts and reposts as well.

#### Response
```ruby
{
  "posts": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "post_type": <CommentRepost|PostRepost|Post>
      "like_count": <int>
      "repost_count": <int>
      "comment_count": <int>
      "post_date": <datetime>
      "reposted_by": <string>
      "user_liked": <boolean>
      "user_reposted": <boolean>
      "user_followed": <boolean>
      "rating": <int>
      "replying_to": <string[]>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

## Comments

### GET /comments/:id
Gets the data of a `Comment`.

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "reply_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "post": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "current_user_following": <boolean>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "parent": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "reply_count": <int>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "replies": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### POST /comments
Creates a new `Comment`.

#### Request
```ruby
{
  "comment": {
    "text": <string>
    "post_id": <bigint>
    "parent_id": <bigint> # optional parent comment being replied to
  }
}
```

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "reply_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "post": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "current_user_following": <boolean>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "parent": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "reply_count": <int>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "replies": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### PUT /comments/:id
Updates `Comment`'s text.

#### Request
```ruby
{
  "comment": {
    "text": <string>
  }
}
```

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "reply_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "post": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "current_user_following": <boolean>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "parent": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "reply_count": <int>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "replies": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### DELETE /comments/:id
Deletes a `Comment`.

#### Response
```ruby
{
  "id": <bigint>
  "text": <string>
  "created_at": <datetime>
  "reply_count": <int>
  "current_user_following": <boolean>
  "author": {
    "id": <bigint>
    "username": <string>
    "display_name": <string>
  }
  "post": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "current_user_following": <boolean>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "parent": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "reply_count": <int>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
  }
  "replies": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

### GET /users/:user_id/comments
Gets the `User`'s created comments.

#### Response
```ruby
[
  {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "reply_count": <int>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    }
    "post": {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "comment_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    "parent": {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "reply_count": <int>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
  }
  ...
]
```

### GET /users/:user_id/linked_comments
Gets the `User`'s created and reposted `Comment`s. 

#### Response
```ruby
{
  "user": {
    "username": <string>
    "display_name": <string>
  },
  "comments": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "post_type": <CommentRepost||Comment>
      "like_count": <int>
      "repost_count": <int>
      "comment_count": <int>
      "post_date": <datetime>
      "user_liked": <boolean>
      "reposted_by": <string>
      "user_reposted": <boolean>
      "user_followed": <boolean>
      "replying_to": <string[]>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

## Likes

### POST /comment_likes
Creates a new `CommentLike`.

#### Request
```ruby
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "CommentLike"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /comment_likes
Deletes a `CommentLike`.

#### Request
```ruby
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "CommentLike"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### POST /post_likes
Creates a new `PostLike`.

#### Request
```ruby
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "PostLike"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /post_likes
Deletes a `PostLike`.

#### Request
```ruby
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "PostLike"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

### GET /users/:user_id/likes
Gets the `Post`s and `Comment`s the `User` liked in order of `Like`.

#### Response
```ruby
{
  "user": {
    "username": <string>
    "display_name": <string>
  }
  "likes": [
    {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "like_type": <PostLike||CommentLike>
      "like_count": <int>
      "repost_count": <int>
      "comment_count": <int>
      "liked_at": <datetime>
      "reposted_by": <string>
      "user_liked": <boolean>
      "user_reposted": <boolean>
      "user_followed": <boolean>
      "replying_to": <string[]>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    }
    ...
  ]
}
```

## Reposts

### POST /comment_reposts
Creates a `CommentRepost`.

#### Request
```ruby
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "CommentRepost"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /comment_reposts
Deletes a `CommentRepost`.

#### Request
```ruby
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "CommentRepost"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### POST /post_reposts
Creates a `PostRepost`.

#### Request
```ruby
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "PostRepost"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /post_reposts
Deletes a `PostRepost`.

#### Request
```ruby
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "type": "PostRepost"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

## Follows

### POST /follows
Creates a `Follow`.

#### Request
```ruby
{
  "follow": {
    "followee_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "follower_id": <bigint>
  "followee_id": <bigint>
}
```

### DELETE /follows
Deletes a `Follow`.

#### Request
```ruby
{
  "follow": {
    "followee_id": <bigint>
  }
}
```

#### Response
```ruby
{
  "follower_id": <bigint>
  "followee_id": <bigint>
}
```

### GET /users/:user_id/subscriptions
Gets the `User`s the `User` is following.

#### Response
```ruby
{
  "id": <bigint>
  "display_name": <string>
  "username": <string>
  "followed_users": [
    {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
      "following_current_user": <boolean>
      "current_user_following": <boolean>
    }
    ...
  ]
}
```

### GET /users/:user_id/followers
Gets the `User`s that follow the `User`.

#### Response
```ruby
{
  "id": <bigint>
  "display_name": <string>
  "username": <string>
  "followers": [
    {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
      "following_current_user": <boolean>
      "current_user_following": <boolean>
    }
    ...
  ]
}
```
