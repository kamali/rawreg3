## module to store key settings, easily accessible by web app, mailers, daemons, etc.
module Settings
  ## cross-env settings:

  ## per env settings:
  if ENV['RAILS_ENV'] =~ /production/

  elsif ENV['RAILS_ENV'] =~ /staging/

  else ## development
    SiteHost = 'localhost:8080'
    SiteName = 'Rawreg Example'
    SiteEmail = 'Rawreg Example <info@localhost>'
    Secret = "Change this random string... #428u3 ksadf 9823fokjh a kajshd fjh92hf3h";
  end

end
