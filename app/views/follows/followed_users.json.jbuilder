json.extract! @user, :id, :display_name, :username

json.followed_users do
  json.array! @followed_users do |followee|
    json.id followee.id
    json.username followee.username
    json.display_name followee.display_name

    json.following_current_user @users_following_current_user.include?(followee.id)
    json.current_user_following @current_user_following_users.include?(followee.id)
  end
end
