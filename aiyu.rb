# frozen_string_literal: true

Dir[File.join(__dir__, 'lib', '*.rb')].sort.each { |file| require file }
require 'yaml'

# Global config
CONFIG          = YAML.load_file(CONFIG_FILE)
DEFAULT_PROFILE = CONFIG['default_profile']
OTHER_ROBOTS    = CONFIG['other_robots']
ADMIN_NAME      = CONFIG['admin_access']
PROFILES        = CONFIG['profiles']
AI_NAME         = CONFIG['ai_name']

# Profile config
profile     = Init.select_profile
SOCIALS_DIR = profile['socials_dir']
TALKER_NAME = profile['talker_name']
PASSWORD    = profile['password']
PROMPT      = profile['prompt']
PORT        = profile['port']
IP          = profile['ip']

# Start Aiyu
Main.new
