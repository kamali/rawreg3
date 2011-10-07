require 'settings';
class Notifications < ActionMailer::Base
  
  def forgot_password(user, password)
    @subject          = "Your new password is ..."
    @recipients       = user.email
    @from             = Settings::SiteEmail
    @headers          = {}
    @user             = user
    @password         = password
  end

  def verify_email(user, sig)
    @subject          = "Please verify your email address..."
    @recipients   = user.email
    @from         = Settings::SiteEmail
    @headers      = {}
    @user         = user
    @sig          = sig
  end

  def change_email(user, new_email, sig)
    @subject           = "To change your email address..."
    @recipients        = new_email
    @from              = Settings::SiteEmail
    @headers           = {}
    @user              = user
    @new_email         = new_email
    @sig               = sig
  end

end
