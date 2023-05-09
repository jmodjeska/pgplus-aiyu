require 'net-telnet'
require_relative 'strings'

class ConnectTelnet
  def initialize
    @client = new_client
  end

  def new_client
    puts "-=> Connecting to: #{TALKER_NAME}"
    File.truncate(LOG, 0) if File.exist?(LOG)
    begin
      client = Net::Telnet::new(
        "Host"         => IP,
        "Port"         => PORT,
        "Prompt"       => /#{PROMPT} \z/n,
        "Timeout"      => TELNET_TIMEOUT,
        "Output_log"   => LOG,
        "Telnetmode"   => true,
        "Binmode"      => true,
        "Debug_Output" => true,
        "Dump_Log"     => true
      )
    rescue Errno::EHOSTUNREACH, Net::OpenTimeout => e
      abort "Can't reach #{IP}:#{PORT}\n".red
    rescue Errno::ECONNREFUSED => e
      abort "Connection refused to #{IP}:#{PORT}.\n".red
    end
    validate_connection
    fork { validate_login }
    client.puts(AI_NAME)
    client.cmd(PASSWORD)
    return client
  end

  private def is_logged(text_to_grep)
    return system("grep '#{text_to_grep}' #{LOG} > /dev/null")
  end

  private def validate_connection
    result = IO.readlines(LOG)[1].chomp!
    unless result == "Connected to #{IP}."
      abort "Connection failed (result: #{result})".red
    end
  end

  private def validate_login
    sleep LOGIN_TOLERANCE
    if is_logged('try again!')
      puts "Password failed for #{AI_NAME}".red
    elsif is_logged('already logged on here') || is_logged('Last logged in')
      puts "-=> Logged in as #{AI_NAME} (`tail -f #{LOG}` to watch)\n".green
    else
      puts "Login failed for #{AI_NAME} (see #{LOG})".red
    end
  end

  def send(cmd)
    stack = ''
    @client.cmd(cmd) { |o| stack << o }
    return stack
  end

  def suppress_go_ahead
    @client.write(IAC + WONT + GA)
  end

  def done
    @client.cmd("quit")
    sleep LOGOUT_TOLERANCE
    if is_logged('for visiting') || is_logged('Please come again!')
      log("Logout successful for #{AI_NAME}", :warn)
    else
      log("Disconnected ungracefully.", :error)
    end
  end
end
