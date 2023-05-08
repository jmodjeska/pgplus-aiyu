require 'time'

# Note: session history follows a player in the case of a direct
# msg (tell); else it treats the main room or specified channel as a
# shared group session.

class Sessions
  attr_accessor :temperature

  def initialize
    @session, @history = {}, {}
    @recons = []
    @temperature = CONFIG.dig('temperature')
    puts "-=> Session manager initialized"
  end

  private def expired(p)
    session_duration = CONFIG.dig('timings', 'session_duration')
    return (@session[p] + 3600 * session_duration) < Time.now
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
    max_reconnects = CONFIG.dig('timings', 'max_reconnects')
    last_recon = @recons.max
    if (Time.now - last_recon) > 3600
      @recons = []
      return true
    elsif @recons.count { |r| (Time.now - r) < 3600 } < max_reconnects
      return true
    else
      return false
    end
  end

  def log_recon
    @recons << Time.now
  end

  def get_history(p, command)
    h = (command == :tell) ? p : command
    if ( (@session.key?(h)) && !(expired(h)) && (@history.key?(h)) )
      @session[h] = Time.now
      return @history[h]
    elsif @session.key?(h)
      @session.delete(h)
      @history.delete(h)
    end
    @session[h] = Time.now
    return []
  end

  def add_to_history(p, msgset, command)
    h = (command == :tell) ? p : command
    if @history.key?(h)
      @history[h].concat encode_msgset(msgset)
    else
      @history[h] = encode_msgset(msgset)
    end
    return @history[h]
  end
end
