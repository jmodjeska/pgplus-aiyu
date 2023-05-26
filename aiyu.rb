# frozen_string_literal: true

Dir[File.join(__dir__, 'lib', '*.rb')].sort.each { |file| require file }
require 'optimist'
require 'yaml'

# Load global config
CONFIG          = YAML.load_file(CONFIG_FILE)
AI_NAME         = CONFIG['ai_name']
ADMIN_NAME      = CONFIG['admin_access']
OTHER_ROBOTS    = CONFIG['other_robots']
DEFAULT_PROFILE = CONFIG['default_profile']

# CLI args
o = Optimist.options do
  banner "\n#{USAGE_BANNER}\n\n"
  opt :profile, 'Specify a talker profile', default: DEFAULT_PROFILE
end

# Load profile data
if CONFIG.dig('profiles', o[:profile])
  SOCIALS_DIR = CONFIG.dig('profiles', o[:profile], 'socials_dir')
  TALKER_NAME = CONFIG.dig('profiles', o[:profile], 'talker_name')
  PASSWORD    = CONFIG.dig('profiles', o[:profile], 'password')
  PROMPT      = CONFIG.dig('profiles', o[:profile], 'prompt')
  PORT        = CONFIG.dig('profiles', o[:profile], 'port')
  IP          = CONFIG.dig('profiles', o[:profile], 'ip')
else
  abort "#{ERR_NO_PROFILE} `#{o[:profile]}`"
end

# Runtime
Main.new
