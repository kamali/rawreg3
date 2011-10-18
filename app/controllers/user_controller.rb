class UserController < ApplicationController

  before_filter :login_required, :only=>['account', 'edit', 'change_email', 'change_password', 'delete']
  before_filter :admin_required, :only=>['admin']

  def account
    @authentications = current_user.authentications
  end

  def signup
    return if params[:user] && params[:user][:roles] ## just to be safe

    @user = User.new(params[:user])
    @user.apply_omniauth(session[:omniauth]) if session[:omniauth]

    @user.timezone  = 'Eastern Time (US & Canada)' unless @user.timezone
    if request.post?  
      @user['validate_password'] = true
      if @user.save
        @user.send_verify_email
        flash[:message] = "Signup successful"
        render :template => 'user/check_email'
        session[:omniauth] = nil if session[:omniauth]
      else
        flash[:warning] = "Signup unsuccessful"
      end
    end
  end

  ## params[:email] means this is a change of address verification
  ## TODO: timeout in email verify link
  def verify
    @user = User.find(params[:id])
    if @user && 
        @user.email_sig(params[:email] || @user.email) == params[:sig] && ## check sig
        (@user.email = params[:email] || @user.email) &&  ## chg email ?
        (params[:email] || @user.verified.blank?) && ## ensure unverified/new if not addr chg
        (@user.verified = true) &&  ## set to verified
        @user.save

      session[:user] = @user.to_session
      flash[:message] = "Email verified"
      if params[:email]
        redirect_to :action => 'account'
      else
        redirect_to_stored :action => 'account' 
      end
    else
      flash[:warning] = "Verification unsuccessful"
    end
  end

  def login
    if request.post?
      if @user = User.authenticate(params[:user][:email], params[:user][:password])
        session[:user] = @user.to_session
        flash[:message]  = "Login successful"
        redirect_to_stored :action => 'account' 
      else
        flash[:warning] = "Login unsuccessful"
      end
    end
    @user = User.new(params[:user]) unless @user
  end

  def logout
    session[:user] = nil
    flash[:message] = 'Logged out'
    redirect_to :action => 'login'
  end

  ## handle any updates to user
  def edit
    return if params[:user] && params[:user][:roles] ## just to be safe
    @user = current_user
    if request.post?  
      @user['validate_password'] = true unless params[:user][:password].blank?
      if params[:user][:email] && params[:user][:email] != @user.email
        new_email = params[:user][:email]
        params[:user][:email] = @user.email
      end
      if @user.update_attributes(params[:user])
        session[:user] = @user.to_session
        flash[:message] = "Changes saved"
        if new_email
          @user.send_change_email(new_email)
          flash[:message] = "Please check your email at #{new_email} to complete the change"
        end
        redirect_to :action => 'account'
      else
        flash[:warning] = "Changes unsuccessful"
      end
    end
  end

  def change_password
    edit
  end
  def change_email
    edit
  end

  def delete
    @user = current_user
    if @user
      @user.deactivate
      flash[:message] = 'Your account has been deleted'
    end
    session[:user] = nil
    redirect_to '/user/signup'
  end

  def forgot_password
    if request.post?
      @user = User.find_by_email(params[:user][:email])
      if @user and @user.send_new_password
        flash[:message]  = "A new password has been sent by email."
        redirect_to :action=>'login'
      else
        flash[:warning]  = "Couldn't send password--please enter the email address you signed up with."
      end
    end
    @user = User.new(params[:user]) unless @user
  end


  def admin
    @user = nil
    if ! params[:search].blank?
      @users =
        User.find(:all,
                  :conditions => "email like '%#{params[:search]}%' OR name like '%#{params[:search]}'",
                  :limit => 100,
                  :order => 'name')
      if @users.length == 1
        @user = @users[0]
        @users = nil
      end

    elsif ! params[:id].blank?
      begin
        @user = User.find(params[:id].to_i)
      rescue
        flash[:warning] = "User #{params[:id].to_i} not found"
      end

      if params[:op]
        if params[:op] == 'delete'
          @user.email = "deleted #{@user.id} #{@user.email}"
          @user.deactivated = 'deleted'
          @user.save
        elsif params[:op] == 'block'
          @user.deactivated = 'blocked'
          @user.save
        elsif params[:op] == 'reactivate'
          @user.email = @user.email.sub(/.*\ /, '')
          @user.deactivated = nil
          @user.save
        end
      elsif params[:user]
        ## clean out optional fields
        if params[:user][:roles] == ''
          params[:user].delete(:roles)
        end
        if (params[:user][:password] == '' and params[:user][:password_confirmation] == '')
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end

        if @user.update_attributes(params[:user])
          flash[:message] = "Changes saved"
        else
          flash[:warning] = "There were errors"
        end
      end

    end ## have params[:id]

  end


  ## login, connect an existing account, or create a new account
  ## via facebook, twitter, linkedin, etc.
  def connect
    omniauth = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])

    ## authentication row matches?
    if authentication
      ## check if token/secret have changed.
      if authentication.token != omniauth['credentials']['token'] ||
          authentication.secret != omniauth['credentials']['secret']
        authentication.token = omniauth['credentials']['token']
        authentication.secret = omniauth['credentials']['secret']
        authentication.save
      end
      flash[:notice] = "Signed in successfully."
      ## log me in
      session[:user] = User.active.find_by_id(authentication.user_id).to_session
      redirect_to_stored '/user/account'

    ## logged in?
    elsif current_user
      
      authentication = Authentication.new(:user_id => current_user.id,
                                          :provider => omniauth['provider'],
                                          :uid => omniauth['uid'],
                                          :token => omniauth['credentials']['token'],
                                          :secret => omniauth['credentials']['secret']
                                          )

      if authentication.save!
        flash[:notice] = "Authentication successful."
      else
        flash[:warning] = "There was a problem connecting your account"
      end
      redirect_to_stored '/user/account'

    ## new user
    else
      user = User.new
      user.apply_omniauth(omniauth)
      user.password = User.random_string(10) if user.password.blank?
      user.verified = true;

      if user.save
        flash[:notice] = "Signed in successfully."
        session[:user] = user.to_session
        redirect_to_stored '/user/account'
      else
        ## don't have all we need? send to signup.
        session[:omniauth] = omniauth ## .except('extra')
        redirect_to '/user/signup'
      end
    end
  end

  def disconnect
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to '/user/account'
  end

  protected

  # This is necessary since Rails 3.0.4
  # See https://github.com/intridea/omniauth/issues/185
  # and http://www.arailsdemo.com/posts/44
  def handle_unverified_request
    true
  end

end
