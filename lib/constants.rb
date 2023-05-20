# frozen_string_literal: true

# Code Version
VERSION = 1.1

# Files
CONFIG_FILE         = 'config/config.yaml'
LOG                 = 'logs/output.log'
DISCLAIMER          = 'config/disclaimer.yaml'
DISCLAIMER_LOG      = 'logs/disclaimer.log.yaml'

# Telnet Commands
IAC  = "\xff"
WONT = "\xfc"
GA   = "\xf9"

# GPT Config
GPT_API_URI         = 'https://api.openai.com/v1/chat/completions'
GPT_API_KEY         = ENV['OPENAI_API_KEY']
GPT_MODEL           = 'gpt-3.5-turbo'
DEFAULT_TEMPERATURE = 1.0
GPT_MAX_TOKENS      = 250
GPT_ROLE            = 'You are a funny and friendly robot who has '\
                      'assumed the name'
GPT_ERR_LIMIT       = "Sorry, I've exceeded my rate limit with ChatGPT. " \
                      'Please try again in a little while.'
GPT_ERR_GENERAL     = "Oh no! Something went wrong and I can't connect to " \
                      "ChatGPT. Sorry about that! I've logged the error so " \
                      'an admin can investigate.'

# Timings
QUEUE_IDLE          =    1   # secs
COMMAND_PACING      =    1   # secs
LOGIN_TOLERANCE     =    2   # secs
LOGOUT_TOLERANCE    =    0.4 # secs
CLEAR_LOG_INTERVAL  =   96   # hours
IDLE_INTERVAL       =   10   # mins
Q_READ_INTERVAL     =    2   # secs
SESSION_DURATION    =    2   # hours
MAX_RECONNECTS      =    2   # per hour
TELNET_TIMEOUT      =    3   # secs
ONE_HOUR            = 3600   # secs

# Static time parts
CLEAR_LOG_SECS      =   13
IDLE_CMD_SECS       =   23
LOG_TIME_MINS       =   38
LOG_TIME_SECS       =   43

# Triggers
CHANNEL_COMMANDS    = %w[cu pu].freeze
CHANNEL_PREFIXES    = ['(UberChannel)', '[UberSpod]'].freeze
DIRECT_MESSAGES     = ['tells you', 'asks of you', 'exclaims to you'].freeze
ROOM_MESSAGES       = %w[says asks exclaims].freeze

# Talker Interactions
MESSAGE_CHUNK_SIZE  = 250 # chars

# Static Strings
SHUTDOWN_MAX_RECON  = 'Max reconnects reached. Exiting.'
SHUTDOWN_GENERAL    = 'Detected shutdown event or interrupt. Exiting.'
CONN_TIMED_OUT      = 'Timed out after initial connection (check prompt?)'
RECON_SIGNAL_MSG    = 'Received Test Reconnect Signal'
INVALID_ENCODING    = 'Invalid encoding detected. Resetting queue.'
MSG_TRUNCATED       = 'Sorry, there was more but I truncated it due to length.'
ERR_NO_PROFILE      = 'Profile does not exist:'
LOGGED_IN_MATCHERS  = ['already logged on here', 'Last logged in'].freeze
LOGGED_OUT_MATCHERS = ['for visiting', 'Please come again!'].freeze

# Config Strings (please keep the original URL intact for license and credit)
DESCRIPTION = "^Y.*^N ChatGPT-connected AI bot v#{VERSION} ^R<3^N ^P^^_^^^N"
URL = 'https://github.com/jmodjeska/pgplus-aiyu'
