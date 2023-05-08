module Admin

  class TestReconnectSignal < StandardError; end

  def test_reconnect
    raise TestReconnectSignal.new "Received Test Reconnect Signal"
  end

  def get_consents
    return YAML.load_file(CONFIG.dig('disclaimer_log')).keys
  end

  def admin_do_cmd(h, callback, p)
    a = CONFIG.dig('admin_access')
    if p != a
      h.send(".#{a} #{p} just tried to execute #{callback}")
      return false
    else
      case callback
      when 'reconnect' then test_reconnect
      when 'list consents' then
        get_consents
        h.send(".#{p} The following people have consented to interact:")
        h.send(".#{p} #{get_consents.join(', ')}")
      else
        h.send(".#{p} Sorry, I don't know how to do '#{callback}'.")
      end
    end
  end
end
