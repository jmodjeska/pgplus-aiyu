module Admin

  class TestReconnectSignal < StandardError; end

  def test_reconnect
    raise TestReconnectSignal.new "Received Test Reconnect Signal"
  end

  def get_consents
    return YAML.load_file(CONFIG.dig('disclaimer_log')).keys
  end

  def admin_do_cmd(h, callback, p, session)
    a = CONFIG.dig('admin_access')
    if p != a
      h.send(".#{a} #{p} just tried to execute #{callback}")
      return false
    else
      case callback
      when 'reconnect' then test_reconnect
      when 'list consents'
        get_consents
        h.send(".#{p} The following people have consented to interact:")
        h.send(".#{p} #{get_consents.join(', ')}")
      when 'get temperature'
        h.send(".#{p} Temperature is currently #{session.temperature}")
      when /^set temperature ([+-]?([0-9]*[.])?[0-9]+)$/
        h.send(".#{p} Temperature is now #{session.set_temperature($1)}")
      when /^session for (.*?)$/
        target = $1
        hist = session.read_history(target)
        if hist.nil?
          h.send(".#{p} I don't have any  session data for #{target}")
        else
          h.send(".#{p} Here is the session data for #{target}")
          h.send(".#{p} #{hist}")
        end
      else
        h.send(".#{p} Sorry, I don't know how to do '#{callback}'.")
      end
    end
  end
end
