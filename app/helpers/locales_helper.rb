require 'http_accept_language'

module LocalesHelper
  LANGUAGES = { 'English' => :en,
                'български' => :'bg-BG',
                'Català' => :ca,
                'čeština' => :cs,
                '正體中文' => :'zh-TW', #zh-Hant, Chinese (traditional), Taiwan
                'Deutsch' => :de,
                'Español' => :es,
                'ελληνικά' => :el,
                'Français' => :fr,
                'Indonesian' => :id,
                'magyar' => :hu,
                '日本語' => :ja,
                '한국어' => :ko,
                'മലയാളം' => :ml,
                'Nederlands' => :'nl-NL',
                'Português (Brasil)' => :'pt-BR',
                'port' => :pt,
                'română' => :ro,
                'Srpski' => :sr,
                'Srpski - Ćirilica' => :'sr-RS',
                'Svenska' => :sv,
                'Tiếng Việt' => :vi,
                'Türkçe' => :tr,
                'українська мова' => :uk }

  def locale_name(locale)
    LANGUAGES.key(locale.to_sym)
  end

  def supported_locales
    LANGUAGES.values
  end

  def valid_locale?(locale)
    return false if locale.blank?
    LANGUAGES.values.include? locale.to_sym
  end

  def language_options_array
    options = []
    LANGUAGES.each_pair do |language, locale|
      options << [language, current_path_with_locale(locale)]
    end
    options
  end

  def selected_language_option
    current_path_with_locale(current_locale)
  end

  def current_path_with_locale(locale)
    url_for(locale: locale)
  end

  def selected_locale
    params[:locale] || current_user_or_visitor.selected_locale
  end

  def locale_selected?
    params.has_key?(:locale) || current_user_or_visitor.locale.present?
  end

  def detected_locale
    (browser_accepted_locales & supported_locales).first
  end

  def default_locale
    I18n.default_locale
  end

  def current_locale
    I18n.locale
  end

  def set_application_locale
    I18n.locale = best_locale
  end

  def best_locale
    if user_signed_in?
      best_available_locale
      binding.pry
    else
      best_cachable_locale
    end
  end

  def best_available_locale
    selected_locale || detected_locale || default_locale
  end

  def best_cachable_locale
    selected_locale || default_locale
  end

  def locale_fallback(first, second = nil)
    first || second || default_locale
  end

  def browser_accepted_locales
    header = request.env['HTTP_ACCEPT_LANGUAGE']
    parser = HttpAcceptLanguage::Parser.new(header)
    parser.user_preferred_languages.map &:to_sym
  end

  def save_detected_locale(user)
    user.update_attribute(:detected_locale, detected_locale)
  end
end
