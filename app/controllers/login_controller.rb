class LoginController < ApplicationController
  before_action :redirect_if_signed_in

  def index
  end

  private

  def redirect_if_signed_in
    redirect_to(matches_path(Season.latest_number, current_user)) if signed_in?
  end
end
