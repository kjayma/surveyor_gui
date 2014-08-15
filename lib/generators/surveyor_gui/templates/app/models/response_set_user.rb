class ResponseSetUser
  def initialize(user_id)
    #find the user.  You can use the commented code below, but switch the model name
    #if your user model is not User.
    #
    #@user = User.find_by_id(user_id)
  end

  def report_user_name
    #return a value to identify users on a report, e.g.:
    #@user ? @user.email : nil
  end
end
