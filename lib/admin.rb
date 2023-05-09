require_relative 'actions'

module Admin
include Actions

  class TestReconnectSignal < StandardError; end

  def test_reconnect
    raise TestReconnectSignal.new "Received Test Reconnect Signal"
  end

  def get_consents
    return YAML.load_file(DISCLAIMER_LOG).keys
  end

  def admin_do_cmd(h, callback, p, session)
    if p != ADMIN_NAME
      h.send(".#{ADMIN_NAME} #{p} just tried to execute #{callback}")
      return false
    else
      available_admin_commands = [
        'reconnect', 'list consents', 'get temperature',
        'set temperature <new temperature>',
        'session for <name or channel>', 'help'
      ]
      case callback
      when 'help'
        h.send(".#{p} I can do the following admin commands:")
        tell(h, p, available_admin_commands.join(', '))
      when 'reconnect'
        test_reconnect
      when 'list consents'
        get_consents
        h.send(".#{p} The following people have consented to interact:")
        tell(h, p, get_consents.join(', '))
      when 'get temperature'
        h.send(".#{p} Temperature is currently #{session.temperature}")
      when /^set temperature ([+-]?([0-9]*[.])?[0-9]+)$/
        h.send(".#{p} Temperature is now #{session.set_temperature($1)}")
      when /^session for (.*?)$/
        target = $1
        hist = session.read_history(target)
        if hist.nil?
          h.send(".#{p} I don't have any session data for #{target}")
        else
          h.send(".#{p} Here is the session data for #{target}")
          tell(h, p, hist.to_s)
        end
      else
        h.send(".#{p} Sorry, I don't know how to do '#{callback}'.")
      end
    end
  end
end
