class UserMailerPreview < ActionMailer::Preview
  def confirmation
    user = User.first
    UserMailer.confirmation(user, user.generate_confirmation_token)
  end
end
