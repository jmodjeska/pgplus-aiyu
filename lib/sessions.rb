require 'time'

# Note: session history (h) follows a player in the case of a direct
# msg (tell); else it treats the main room or specified channel as a
# shared group session.

class Sessions
  def initialize
    @session, @history = {}, {}
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
    arr = [
      {"role": "user", "content": o},
      {"role": "assistant", "content": i}
    ]
    return arr
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
