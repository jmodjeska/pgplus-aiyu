# frozen_string_literal: true

require_relative 'actions'

# Process commands that the designated admin can directly issue to Aiyu
class Admin
  include Actions

  def initialize(conn, task, session)
    @cmd = task[:callback].split.first
    @p = task[:p]
    @s = session
    @conn = conn
    @task = task
    @clist = ADMIN_COMMANDS
  end

  def do_admin_cmd
    return unless valid_admin?
    return unless valid_admin_cmd?
    __send__(@clist[@cmd][:cmd])
  end

  private

  def valid_admin?
    return true if @p == ADMIN_NAME
    @conn.send(".#{ADMIN_NAME} #{@p} just tried to execute #{@cmd}")
    return false
  end

  def valid_admin_cmd?
    return true if @clist.key?(@cmd)
    @conn.send(".#{@p} I don't know how to do '#{@cmd}'.")
    return false
  end

  def args
    return @task[:callback].split[1..]
  end

  def help_response
    cmds = @clist.flat_map { |k, v| v[:options]&.map { |o| "#{k} #{o}" } || k }
    tell(@conn, @p, "#{ADMIN_HELPMSG} #{cmds.join(', ')}")
  end

  def test_reconnect
    raise TestReconnectSignal, RECON_SIGNAL_MSG
  end

  def list_data
    case args[0]
    when 'consents' then list_consents
    when 'sessions' then list_sessions
    else @conn.send(".#{@p} I don't know how to list '#{args[0]}'.")
    end
  end

  def list_consents
    @conn.send(".#{@p} #{ADMIN_INTERACT}")
    tell(@conn, @p, YAML.load_file(DISCLAIMER_LOG).keys.join(', '))
  end

  def list_sessions
    if @s.session.empty?
      @conn.send(".#{@p} #{ADMIN_NOSESSIONS}")
    else
      list = @s.session.keys.join(', ')
      tell(@conn, @p, "#{ADMIN_SESSIONS} #{list}")
    end
  end

  def session_data
    hist = @s.read_history(args[0])
    msg = hist.nil? ? "I don't have any" : 'Here is the'
    @conn.send(".#{@p} #{msg} session data for #{args[0]}")
    tell(@conn, @p, hist.to_s) unless hist.nil?
  end

  def admin_temp
    msg = ".#{@p} Temperature"
    case args[0]
    when 'get' then @conn.send("#{msg} is #{@s.temp}")
    when 'set' then @conn.send("#{msg} set to #{@s.update_temp(args[1])}")
    else @conn.send(".#{@p} I don't know how to do that.")
    end
  end
end
