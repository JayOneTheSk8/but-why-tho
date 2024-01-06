json.extract! @user, :id, :display_name, :username

json.followers do
  json.array! @followers do |follower|
    json.id follower.id
    json.username follower.username
    json.display_name follower.display_name

    json.following_current_user @users_following_current_user.include?(follower.id)
    json.current_user_following @current_user_following_users.include?(follower.id)
  end
end
