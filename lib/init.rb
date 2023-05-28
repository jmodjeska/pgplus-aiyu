# frozen_string_literal: true

# Initialize profile data
module Init
  require 'optimist'
  extend self

  def select_profile
    profile = process_args[:profile]
    abort "#{ERR_NO_PROFILE} `#{profile}`" unless PROFILES[profile]
    return PROFILES[profile]
  end

  private

  def process_args
    o = Optimist.options do
      banner "\n#{USAGE_BANNER}\n\n"
      opt :profile, PROFILE_ARG, default: DEFAULT_PROFILE
    end
    return o
  end
end
