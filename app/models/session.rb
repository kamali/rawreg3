class Session

  attr_accessor :id, :name, :roles, :timezone

  def initialize(user)
    @id = user['id']
    @name = user['name']
    @roles = user['roles']
    @timezone = user['timezone']
  end

end
