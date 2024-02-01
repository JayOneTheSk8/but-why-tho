# Y (Server)

`Why` is a platform for posting questions and asking more. Users can create posts and comments as long as they're all questions, encouraging deeper thought. Users can also follow each other and like and repost posts and comments. Posts and highly reposted comments are aggregated onto the front page. For a currated list, a user can view a front page of their followed users.

Table of Contents
===================
- [Installation](#installation)
- [API Specs](#api-specs)
  - [Authentication](#authentication)
    - [POST /sign_up](#post-sign_up)
    - [POST /sign_in](#post-sign_in)
    - [GET /sign_out](#get-sign_out)
    - [GET /sessions](#get-sessions)
  - [Users](#users)
    - [GET /users/:username](#get-usersusername)
    - [PUT /users/:id](#put-usersid)
  - [Posts](#posts)
    - [GET /posts](#get-posts)
    - [GET /posts/:id](#get-postsid)
    - [POST /posts](#post-posts)
    - [PUT /posts/:id](#put-postsid)
    - [DELETE /posts/:id](#delete-postsid)
    - [GET /users/:user_id/posts](#get-usersuser_idposts)
    - [GET /users/:user_id/linked_posts](#get-usersuser_idlinked_posts)
    - [GET /front_page](#get-front_page)
    - [GET /front_page_following](#get-front_page_following)
    - [GET /posts/:post_id/data](#get-postspost_iddata)
  - [Comments](#comments)
    - [GET /comments/:id](#get-commentsid)
    - [POST /comments](#post-comments)
    - [PUT /comments/:id](#put-commentsid)
    - [DELETE /comments/:id](#delete-commentsid)
    - [GET /users/:user_id/comments](#get-usersuser_idcomments)
    - [GET /users/:user_id/linked_comments](#get-usersuser_idlinked_comments)
    - [GET /comments/:comment_id/data](#get-commentscomment_iddata)
  - [Likes](#likes)
    - [POST /comment_likes](#post-comment_likes)
    - [DELETE /comment_likes](#delete-comment_likes)
    - [POST /post_likes](#post-post_likes)
    - [DELETE /post_likes](#delete-post_likes)
    - [GET /users/:user_id/likes](#get-usersuser_idlikes)
  - [Reposts](#reposts)
    - [POST /comment_reposts](#post-comment_reposts)
    - [DELETE /comment_reposts](#delete-comment_reposts)
    - [POST /post_reposts](#post-post_reposts)
    - [DELETE /post_reposts](#delete-post_reposts)
    - [GET /users/:user_id/reposts](#get-usersuser_idreposts)
  - [Follows](#follows)
    - [POST /follows](#post-follows)
    - [DELETE /follows](#delete-follows)
    - [GET /users/:username/subscriptions](#get-usersusernamesubscriptions)
    - [GET /users/:username/followers](#get-usersusernamefollowers)

Installation
===================

Requires `ruby-3.2.2` and [postgresql](https://www.postgresql.org/download/)

```
bundle install
bin/rails db:migrate
```

### Run Server

```sh
bin/rails s
```

### Lint (via Rubocop)
```sh
bin/rubocop
```

### Run Test Specs
```sh
bin/rspec
```

## Set up for HTTPS (Required for cross-site browser cookies)

Install [`openssl`](https://www.openssl.org/)

```sh
# via Ubunutu
sudo apt install openssl
```

Create local key/certificate

```sh
# From top-repo level (lasts 1 year)
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -keyout config/ssl/localhost.key -out config/ssl/localhost.crt -subj  "/CN=localhost" -days 365
```

Run server via puma config
```sh
bundle exec puma -C config/puma.rb
```

API Specs
===================

## Authentication

### POST /sign_up
Creates a new `User` and signs them in.

#### Request
```yaml
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
```yaml
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
```yaml
{
  "user": {
    "login": <string> # Username or email for user
    "password": <string>
  }
}
```

#### Response
```yaml
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
```yaml
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
```yaml
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
  "current_user_following": <boolean>
  "post_count": <int>
  "following_count": <int>
  "follower_count": <int>
}
```

### PUT /users/:id
Edits the `User`.

#### Request
```yaml
{
  "user": {
    "display_name": <string>
    "email": <string>
  }
}
```

#### Response
```yaml
{
  "id": <bigint>
  "username": <string>
  "display_name": <string>
  "email": <string>
  "current_user_following": <boolean>
  "post_count": <int>
  "following_count": <int>
  "follower_count": <int>
}
```

## Posts

### GET /posts
Gets all `Post`s by lastest creation date.

#### Response
```yaml
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
```yaml
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
```yaml
{
  "post": {
    "text": <string>
  }
}
```

#### Response
```yaml
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
```yaml
{
  "post": {
    "text": <string>
  }
}
```

#### Response
```yaml
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
```yaml
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
```yaml
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
```yaml
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
      "reposted_by_username": <string> # username of reposter; optional
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

### GET /front_page
Gets the most popular `Post`s and reposted (at least 5 times) `Comment`s by date and popularity.

#### Response
```yaml
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
```yaml
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
      "reposted_by_username": <string>
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

### GET /posts/:post_id/data
Gets the `Post`'s full data with its associated top-level comments. 

#### Response
```yaml
{
  "post": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "like_count": <int>
    "repost_count": <int>
    "user_liked": <boolean>
    "user_reposted": <boolean>
    "user_followed": <boolean>
    "replying_to": null
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    },
    "comments": [
      {
        "id": <bigint>
        "text": <string>
        "created_at": <datetime>
        "comment_count": <int>
        "like_count": <int>
        "repost_count": <int>
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
}
```

## Comments

### GET /comments/:id
Gets the data of a `Comment`.

#### Response
```yaml
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
```yaml
{
  "comment": {
    "text": <string>
    "post_id": <bigint>
    "parent_id": <bigint> # optional parent comment being replied to
  }
}
```

#### Response
```yaml
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
```yaml
{
  "comment": {
    "text": <string>
  }
}
```

#### Response
```yaml
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
```yaml
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
```yaml
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
```yaml
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
      "reposted_by_username": <string>
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

### GET /comments/:comment_id/data
Gets the `Comment`'s full data with its associated post and optional parent and replies. 

#### Response
```yaml
{
  "comment": {
    "id": <bigint>
    "text": <string>
    "created_at": <datetime>
    "comment_count": <int>
    "like_count": <int>
    "repost_count": <int>
    "user_liked": <boolean>
    "user_reposted": <boolean>
    "user_followed": <boolean>
    "replying_to": <string[]>
    "author": {
      "id": <bigint>
      "username": <string>
      "display_name": <string>
    },
    "post": {
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "comment_count": <int>
      "like_count": <int>
      "repost_count": <int>
      "user_liked": <boolean>
      "user_reposted": <boolean>
      "user_followed": <boolean>
      "replying_to": null
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    },
    "parent": { # nullable
      "id": <bigint>
      "text": <string>
      "created_at": <datetime>
      "comment_count": <int>
      "like_count": <int>
      "repost_count": <int>
      "user_liked": <boolean>
      "user_reposted": <boolean>
      "user_followed": <boolean>
      "replying_to": <string[]>
      "author": {
        "id": <bigint>
        "username": <string>
        "display_name": <string>
      }
    },
    "comments": [
      {
        "id": <bigint>
        "text": <string>
        "created_at": <datetime>
        "comment_count": <int>
        "like_count": <int>
        "repost_count": <int>
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
}
```

## Likes

### POST /comment_likes
Creates a new `CommentLike`.

#### Request
```yaml
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "CommentLike"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /comment_likes
Deletes a `CommentLike`.

#### Request
```yaml
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "CommentLike"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### POST /post_likes
Creates a new `PostLike`.

#### Request
```yaml
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "PostLike"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /post_likes
Deletes a `PostLike`.

#### Request
```yaml
{
  "like": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "PostLike"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

### GET /users/:user_id/likes
Gets the `Post`s and `Comment`s the `User` liked in order of `Like`.

#### Response
```yaml
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
      "reposted_by_username": <string>
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
```yaml
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "CommentRepost"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /comment_reposts
Deletes a `CommentRepost`.

#### Request
```yaml
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "CommentRepost"
  "comment_id": <bigint>
  "user_id": <bigint>
}
```

### POST /post_reposts
Creates a `PostRepost`.

#### Request
```yaml
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "type": "PostRepost"
  "post_id": <bigint>
  "user_id": <bigint>
}
```

### DELETE /post_reposts
Deletes a `PostRepost`.

#### Request
```yaml
{
  "repost": {
    "message_id": <bigint>
  }
}
```

#### Response
```yaml
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
```yaml
{
  "follow": {
    "followee_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "follower_id": <bigint>
  "followee_id": <bigint>
}
```

### DELETE /follows
Deletes a `Follow`.

#### Request
```yaml
{
  "follow": {
    "followee_id": <bigint>
  }
}
```

#### Response
```yaml
{
  "follower_id": <bigint>
  "followee_id": <bigint>
}
```

### GET /users/:username/subscriptions
Gets the `User`s the `User` is following.

#### Response
```yaml
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

### GET /users/:username/followers
Gets the `User`s that follow the `User`.

#### Response
```yaml
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
