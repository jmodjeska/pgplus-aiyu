require 'time'

class Sessions
  def initialize
    @session, @history = {}, {}
  end

  private def expired(p)
    session_duration = CONFIG.dig('timings', 'session_duration')
    return (@session[p] + 3600 * session_duration) < Time.now
  end

  private def encode_msgset(msgset)
    outbound, inbound = msgset
    arr = [
      {"role": "user", "content": outbound},
      {"role": "assistant", "content": inbound}
    ]
    return arr
  end

  def get_history(p)
    if ( (@session.key?(p)) && !(expired(p)) && (@history.key?(p)) )
      @session[p] = Time.now
      return @history[p]
    elsif @session.key?(p)
      @session.delete(p)
      @history.delete(p)
    end
    @session[p] = Time.now
    return []
  end

  def add_to_history(p, msgset)
    if @history.key?(p)
      @history[p].concat encode_msgset(msgset)
    else
      @history[p] = encode_msgset(msgset)
    end
    return @history[p]
  end

  # TODO: Handle room / channel sessions
end
