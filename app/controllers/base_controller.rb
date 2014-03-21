class BaseController < ApplicationController
  include AutodetectTimeZone
  include OmniauthAuthenticationHelper

  before_filter :authenticate_user!, :check_browser

  before_filter :check_for_omniauth_authentication,
                :check_for_invitation,
                :load_announcements,
                :initialize_search_form,
                :set_time_zone_from_javascript, if: :user_signed_in?

  after_filter  :set_csrf_cookie_for_ng

  helper_method :time_zone
  helper_method :permitted_params

  protected

  def permitted_params
    @permitted_params ||= PermittedParams.new(params, current_user)
  end

  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || form_authenticity_token == request.headers['X_XSRF_TOKEN']
  end

  protected
  def initialize_search_form
    @search_form = SearchForm.new(current_user)
  end

  def load_announcements
    if current_user and not request.xhr?
      @current_and_not_dismissed_announcements = Announcement.current_and_not_dismissed_by(current_user)
    end
  end

  def check_browser
    redirect_to browser_not_supported_url if browser.ie6?
  end

  def check_for_invitation
    if session[:invitation_token]
      redirect_to invitation_path(session[:invitation_token])
    end
  end
end
