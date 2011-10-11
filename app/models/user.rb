require 'digest/sha2'
require 'settings'
class User < ActiveRecord::Base

  validates_presence_of :name ## OPTIONAL
  validates_presence_of :salt

  validates_length_of :password, :within => 6..40, :if => Proc.new{ |u| u['validate_password'] }
  validates_presence_of :password, :password_confirmation, :if => Proc.new{ |u| u['validate_password'] }
  validates_confirmation_of :password, :if => Proc.new{ |u| u['validate_password'] }

  validates_presence_of :email, :unless => :deactivated
  validates_uniqueness_of :email, :unless => :deactivated
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email", :unless => :deactivated

  attr_protected :id, :salt
  attr_accessor :password, :password_confirmation

  scope :active, :conditions => "user.verified=1 AND deactivated IS NULL"

  has_many :authentications

  ############

  ## class methods to sign strings with our secret
  ## TODO: just use config.action_controller.session[:secret] instead of Settings::Secret
  def self.sign(*strings)
    string = [Settings::Secret, strings.map{ |s| s.to_s} ].flatten.join 
    Digest::SHA2.hexdigest( string ) 
  end 
  def self.short_sig(length, *strings)
    (self.sign(strings)[0,length])
  end

  ## create a random password string
  ## sign it with our secret to make it further unguessable
  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    string = ""
    1.upto(len) { |i| string << chars[rand(chars.size-1)] }

    return self.short_sig(len, string)
  end

  ## no need to sign passwords with the secret,
  ## as they're already reflected in the salt
  def self.encrypt_password(pass, salt)
    Digest::SHA1.hexdigest(pass+salt)
  end

  ############

  def self.authenticate(email, pass)
    #u = find(:first, :conditions=>["email = ? AND verified=1 AND deactivated IS NULL", email])
    u = User.active.find(:first, :conditions=>["email = ?", email])
    return u if u && User.encrypt_password(pass, u.salt) == u.hashed_password
    nil
  end

  def password=(pass)
    @password=pass
    self.salt = User.random_string(10) if self.salt.blank?
    self.hashed_password = User.encrypt_password(@password, self.salt)
  end

  def send_new_password
    new_pass = User.random_string(10)
    self.password = self.password_confirmation = new_pass
    self.save
    Notifications.forgot_password(self, new_pass).deliver
  end


  def email_sig(new_email)
    return User.short_sig(12, 'email_sig', id, new_email)
  end

  def send_verify_email
    Notifications.verify_email(self, email_sig(self.email)).deliver
  end
  
  def send_change_email(new_email)
    Notifications.change_email(self, new_email, email_sig(new_email)).deliver
  end
  
  def verify_email(new_email, sig)
    if (sig == email_sig(new_email))
      email = new_email
      user.save!
    end
    nil
  end

  ## return a stripped down object for storage in the session
  ## keeps the cookie lean, and avoids issues like having email in the cookie.
  ## (the latter could be solved with encrypted cookies.)
  def to_session
    # return self ## if want to use full user object in session
    Session.new( self )
  end

  ## TODO: delete authentication rows
  def deactivate
    email = nil
    deactivated = 'deactivated'
    user.save!
  end

  def block
    deactivated = 'blocked'
    user.save!
  end

  ## omniauth
  ## TODO: get timezone from offset, something like? ActiveSupport::TimeZone[-8]
  def apply_omniauth(omniauth)
    if email.blank? && omniauth['user_info']['email']
      self.email = omniauth['user_info']['email']
      self.verified = true
    end
    self.name = omniauth['user_info']['name'] if name.blank?
    self.timezone = 'Eastern Time (US & Canada)' if timezone.blank?
    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

end
