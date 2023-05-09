# Files
CONFIG_FILE         = 'config/config.yaml'
LOG                 = 'logs/output.log'
DISCLAIMER          = 'config/disclaimer.yaml'
DISCLAIMER_LOG      = 'logs/disclaimer.log.yaml'
DEFAULT_TEMPERATURE = 1.0

# Telnet Commands
IAC  = "\xff"
WONT = "\xfc"
GA   = "\xf9"

# Timings
SLOWNESS_TOLERANCE  =    3 # seconds
CLEAR_LOG_INTERVAL  =   96 # hours
IDLE_INTERVAL       =   10 # mins
Q_READ_INTERVAL     =    2 # secs
SESSION_DURATION    =    2 # hours
MAX_RECONNECTS      =    2 # per hour
TELNET_TIMEOUT      =    3 # seconds
ONE_HOUR            = 3600 #seconds

# Triggers
CHANNEL_COMMANDS    = ['cu', "pu"]
CHANNEL_PREFIXES    = ["(UberChannel)", "[UberSpod]"]
DIRECT_MESSAGES     = ["tells you", "asks of you", "exclaims to you"]
ROOM_MESSAGES       = ["says", "asks", "exclaims"]