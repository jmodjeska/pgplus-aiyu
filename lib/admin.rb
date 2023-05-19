# frozen_string_literal: true

require_relative 'actions'

# Commands that the designated admin can directly issue to Aiyu
module Admin
  include Actions

  ADMIN_COMMANDS = [
    'reconnect', 'list consents', 'list sessions', 'get temperature',
    'set temperature <new temperature>', 'session for <name or channel>',
    'help'
  ].freeze

  def do_admin_cmd(conn, task, session)
    return unless check_valid_admin(conn, task[:p])
    case task[:callback]
    when 'help' then help_response(conn, task[:p])
    when 'reconnect' then test_reconnect
    when /list (.*?)$/ then list_data(conn, task[:p], session, $1)
    when /[g|s]et temperature/ then admin_temperature(conn, task, session)
    when /^session for (.*?)$/ then show_session(conn, task, session, $1)
    else conn.send(".#{task[:p]} I don't know how to do '#{task[:callback]}'.")
    end
  end

  class TestReconnectSignal < StandardError; end

  def test_reconnect
    raise TestReconnectSignal, 'Received Test Reconnect Signal'
  end

  private

  def check_valid_admin(conn, player)
    return true if player == ADMIN_NAME
    conn.send(".#{ADMIN_NAME} #{player} just tried to execute #{callback}")
    return false
  end

  def list_data(conn, player, session, data_to_list)
    case data_to_list
    when 'consents' then list_consents(conn, player)
    when 'sessions' then list_sessions(conn, player, session)
    else conn.send(".#{task[:p]} I don't know how to list '#{data_to_list}'.")
    end
  end

  def list_consents(conn, player)
    conn.send(".#{player} The following people have consented to interact:")
    tell(conn, player, YAML.load_file(DISCLAIMER_LOG).keys.join(', '))
  end

  def list_sessions(conn, player, session)
    if session.session.empty?
      conn.send(".#{player} No active sessions.")
      return
    end
    list = session.session.keys.join(', ')
    tell(conn, player, "The following people have active sessions: #{list}")
  end

  def help_response(conn, player)
    conn.send(".#{player} I can do the following admin commands:")
    tell(conn, player, ADMIN_COMMANDS.join(', '))
  end

  def admin_temperature(conn, task, session)
    case task[:callback]
    when 'get temperature'
      conn.send(".#{task[:p]} Temperature is currently #{session.temp}")
    when /^set temperature ([+-]?([0-9]*[.])?[0-9]+)$/
      temp = ::Regexp.last_match(1)
      conn.send(".#{task[:p]} Temperature is now #{session.update_temp(temp)}")
    end
  end

  def show_session(conn, task, session, target)
    hist = session.read_history(target)
    if hist.nil?
      conn.send(".#{task[:p]} I don't have any session data for #{target}")
    else
      conn.send(".#{task[:p]} Here is the session data for #{target}")
      tell(conn, task[:p], hist.to_s)
    end
  end
end
