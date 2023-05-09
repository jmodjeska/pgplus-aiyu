# Code Version
VERSION = 1.0

# Files
CONFIG_FILE         = 'config/config.yaml'
LOG                 = 'logs/output.log'
DISCLAIMER          = 'config/disclaimer.yaml'
DISCLAIMER_LOG      = 'logs/disclaimer.log.yaml'

# Telnet Commands
IAC  = "\xff"
WONT = "\xfc"
GA   = "\xf9"

#GPT Config
GPT_API_URI         = 'https://api.openai.com/v1/chat/completions'
GPT_API_KEY         = ENV['OPENAI_API_KEY']
GPT_MODEL           = 'gpt-3.5-turbo'
DEFAULT_TEMPERATURE = 1.0
GPT_MAX_TOKENS      = 250

# Timings
LOGIN_TOLERANCE     =    2   # secs
LOGOUT_TOLERANCE    =    0.4 # secs
CLEAR_LOG_INTERVAL  =   96   # hours
IDLE_INTERVAL       =   10   # mins
Q_READ_INTERVAL     =    2   # secs
SESSION_DURATION    =    2   # hours
MAX_RECONNECTS      =    2   # per hour
TELNET_TIMEOUT      =    3   # secs
ONE_HOUR            = 3600   # secs

# Triggers
CHANNEL_COMMANDS    = ['cu', "pu"]
CHANNEL_PREFIXES    = ["(UberChannel)", "[UberSpod]"]
DIRECT_MESSAGES     = ["tells you", "asks of you", "exclaims to you"]
ROOM_MESSAGES       = ["says", "asks", "exclaims"]

# Config Strings (please keep the original URL intact for license and credit)
DESCRIPTION = "^Y.*^N ChatGPT-connected AI bot v#{VERSION} ^R<3^N ^P^^_^^^N"
URL = "https://github.com/jmodjeska/pgplus-aiyu"
