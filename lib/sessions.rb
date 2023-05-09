require 'time'

# Note: session history follows a player in the case of a direct
# msg (tell); else it treats the main room or specified channel as a
# shared group session.

class Sessions
  attr_accessor :temperature

  def initialize
    @session, @history = {}, {}
    @recons = []
    @temperature = DEFAULT_TEMPERATURE
    puts "-=> Session manager initialized"
  end

  private def expired(p)
    return (@session[p] + ONE_HOUR * SESSION_DURATION) < Time.now
  end

  private def encode_msgset(msgset)
    o, i = msgset
    [o, i].each do |str|
      str.force_encoding('UTF-8')
      str.encode!('UTF-8', 'binary',
        invalid: :replace, undef: :replace, replace: '')
    end
    return [
      {"role": "user", "content": o},
      {"role": "assistant", "content": i}
    ]
  end

  def set_temperature(temp)
    @temperature = temp.to_f
  end

  def recons_available
    return true if @recons.empty?

    last_recon = @recons.max
    if (Time.now - last_recon) > ONE_HOUR
      @recons = []
      return true
    elsif @recons.count { |r| (Time.now - r) < ONE_HOUR } < MAX_RECONNECTS
      return true
    else
      return false
    end
  end

  def log_recon
    @recons << Time.now
  end

  def get_history(p, command)
    hist = (command == :tell) ? p : command
    if ( (@session.key?(hist)) && !(expired(hist)) && (@history.key?(hist)) )
      @session[hist] = Time.now
      return @history[hist]
    elsif @session.key?(hist)
      @session.delete(hist)
      @history.delete(hist)
    end
    @session[hist] = Time.now
    return []
  end

  def read_history(str)
    @history[str]
  end

  def add_to_history(p, msgset, command)
    hist = (command == :tell) ? p : command
    if @history.key?(hist)
      @history[hist].concat encode_msgset(msgset)
    else
      seed_msgset = [{
        "role": "system",
        "content": "You are a funny and friendly assistant who "\
        "has assumed the name #{AI_NAME}."
      }]
      @history[hist] = seed_msgset
      @history[hist].concat encode_msgset(msgset)
    end
    return @history[hist]
  end
end
