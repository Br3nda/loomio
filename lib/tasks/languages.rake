# zeus rake languages:update

namespace :languages do
  LOGIN = { basic_auth: {username: ENV['TRANSIFEX_USERNAME'], password: ENV['TRANSIFEX_PASSWORD']} }

  RESOURCES = { 'github-linked-version' => 'en.yml',
                'frontpageenyml'        => 'frontpage.en.yml' }

  THRESHOLDS = { "Live" => 80 }

  task :update => :environment do
    language_info = HTTParty.get('http://www.transifex.com/api/2/project/loomio-1/languages', LOGIN)
    locales = locale_array(language_info)
    puts "current languages = #{locales}"

    # note we're only fetching stats on the Main resource
    language_stats = HTTParty.get('http://www.transifex.com/api/2/project/loomio-1/resource/github-linked-version/stats', LOGIN)


    locales.each do |locale|
      printf '%20s %16s', cyan(locale), status(locale, language_stats)

      RESOURCES.keys.each do |resource|
        update(locale, resource)
      end
      print "\n"
    end

    print "\n"
    Rake::Task["languages:check_variables"].invoke
    print "\n"
    print "\n"
    puts "DONE!! ^_^"
    print "\n"
  end

  task :check_variables => :environment do
    RESOURCES.values.each do |file|
      print "CHECKING KEYS AGAINST #{cyan(file)} \n\n"

      source_language_hash = YAML.load(File.read("config/locales/#{file}"))
      keys_with_variables = find_keys_with_variables(source_language_hash).map {|key| key[2..-2] }

      LocalesHelper::LANGUAGES.values.each do |locale|
        keys_with_variables.each do |key|
          english_str = I18n.t(key, locale: :en)
          foreign_str = I18n.t(key, locale: locale)
          english_variables = parse_for_variables english_str
          foreign_variables = parse_for_variables foreign_str

          if english_variables.any? { |var| !foreign_variables.include?(var) }
            bolded_english = english_str.gsub('%{', "\e[1m%{").gsub('}', "}\e[22m")

            print "  #{locale.to_s}#{key}\n"
            print "\t\e[32m#{bolded_english}\e[0m\n"
            print "\t#{foreign_str}\n\n"
            print "\t\e[30mhttps://www.transifex.com/projects/p/loomio-1/translate/##{locale.to_s}/#{RESOURCES.key(file)}/?key=#{key[1..-1]}\e[0m\n\n"
          end
        end
      end

    end

  end
end


#this method returns all key-chains which have variables in them.
def find_keys_with_variables(input_hash, key_trace = '')
  target_keys = []

  input_hash.keys.each do |key|
    extended_key_trace = key_trace + key + '.'

    hash_or_string = input_hash[key]
    if hash_or_string.is_a? Hash
      result_from_deeper = find_keys_with_variables(hash_or_string, extended_key_trace)
      target_keys << result_from_deeper unless result_from_deeper.empty?
    else
      target_keys << extended_key_trace if contains_variables?(hash_or_string)
    end
  end

  target_keys.flatten
end

def parse_for_variables(str)
  str.scan(/%{[^%{}]*}/)
end

def contains_variables?(str)
  parse_for_variables(str).present?
end

##############

def update(locale, resource)
  fixed_locale = locale.gsub('_', '-')
  filename = RESOURCES[resource].chomp('en.yml') + "#{fixed_locale}.yml"

  response = HTTParty.get("http://www.transifex.com/api/2/project/loomio-1/resource/#{resource}/translation/#{locale}", LOGIN)

  if response.present? && content = response['content']
    target = File.open("config/locales/#{filename}", 'w')
    target.write(content.gsub(locale, fixed_locale))
    target.close()

    printf "%18s ", grey(filename)
  else
    puts "ERROR!! -- #{locale} - #{filename}"
  end
end

def status(locale, language_stats)
  locale = locale.to_sym
  perc_comp_str = percent_complete(locale, language_stats)
  perc_comp = perc_comp_str.to_i
    perc_comp_str += " " unless perc_comp == 100
    perc_comp_str += " " if perc_comp < 10

  if LocalesHelper::LANGUAGES.values.include? locale
    if perc_comp >= THRESHOLDS["Live"] - 5
      "\e[1mLive\e[22m #{perc_comp_str}"
    else
      red("Live #{perc_comp_str}")
    end

  else
    if perc_comp >= THRESHOLDS["Live"] - 10
      green(" ^   #{perc_comp_str}")
    else
       grey(" -   #{perc_comp_str}")
    end
  end
end

def percent_complete(locale, language_stats)
  language_stats.with_indifferent_access[locale]["completed"]
end

def green(string)
  "\e[92m#{string}\e[0m"
end

def red(string)
  "\e[91m#{string}\e[0m"
end

def grey(string)
  "\e[30m#{string}\e[0m"
end

def cyan(string)
  "\e[96m#{string}\e[0m"
end

def locale_array(language_info)
  language_info.map {|l| l['language_code'] }
end

