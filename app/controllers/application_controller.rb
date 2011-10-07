class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '375a0cf1efc1ca91d6f87d2f7fb15ad2'
  
  before_filter :set_timezone

  def set_timezone
    Time.zone = logged_in ? logged_in.timezone : 'Eastern Time (US & Canada)'
  end

  def login_required
    return true if logged_in
    return send_to_login
  end

  def admin_required
    return true if is_admin?
    return send_to_login
  end

  def send_to_login
    flash[:warning]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to :controller => "user", :action => "login"
    return false
  end

  ## return a stripped down quasi-user object for storage in the session
  def logged_in
    session[:user]
  end
  helper_method :logged_in

  def is_admin?
    logged_in && logged_in.roles =~ /\badmin\b/
  end
  helper_method :is_admin?

  ## the full user object pulled from the db
  def current_user
    return @current_user if defined?( @current_user )
    if logged_in
      @current_user =
        User.find(:first, 
                  :conditions => ["id = ? AND deactivated IS NULL AND verified IS NOT NULL", 
                                  logged_in.id])
    else
      @current_user = nil
    end
  end
  helper_method :current_user

  def redirect_to_stored(default = nil)
    if ! session[:return_to].blank?
      redirect_to(session[:return_to])
      session[:return_to]=nil
    else
      redirect_to( default || "/" )
    end
  end

end
