# frozen_string_literal: true

require 'net-telnet'
require_relative 'strings'

# Talker transmission layer
class ConnectTelnet
  include Strings

  def initialize
    init_outputs
    @client = new_client
  end

  def new_client
    client = init_client
    validate_connection
    client_login(client)
    return client
  rescue Errno::EHOSTUNREACH, Net::OpenTimeout
    abort "Can't reach #{IP}:#{PORT}\n".red
  rescue Errno::ECONNREFUSED
    abort "Connection refused to #{IP}:#{PORT}.\n".red
  end

  def send(cmd)
    stack = String.new('')
    @client.cmd(cmd) { |o| stack << o }
    return stack
  end

  def suppress_go_ahead
    @client.write(IAC + WONT + GA)
  end

  def done
    @client.cmd('wave')
    @client.cmd('quit')
    sleep LOGOUT_TOLERANCE
    if LOGGED_OUT_MATCHERS.any? { |v| logged?(v) }
      log("Logout successful for #{AI_NAME}", :warn)
    else
      log('Disconnected ungracefully.', :error)
    end
  end

  private

  def init_outputs
    puts "-=> Connecting to: #{TALKER_NAME}"
    File.truncate(LOG, 0) if File.exist?(LOG)
  end

  def init_client
    return Net::Telnet.new(client_host_config.merge(client_output_config))
  end

  def client_host_config
    return {
      'Host' => IP,
      'Port' => PORT,
      'Prompt' => /#{PROMPT} \z/n
    }
  end

  def client_output_config
    return {
      'Timeout' => TELNET_TIMEOUT,
      'Output_log' => LOG,
      'Telnetmode' => true,
      'Binmode' => true,
      'Debug_Output' => true,
      'Dump_Log' => true
    }
  end

  def client_login(client)
    fork { validate_login }
    client.puts(AI_NAME)
    client.cmd(PASSWORD)
  end

  def validate_login
    sleep LOGIN_TOLERANCE
    if logged?('try again!')
      puts "Password failed for #{AI_NAME}".red
    elsif LOGGED_IN_MATCHERS.any? { |v| logged?(v) }
      puts "-=> Logged in as #{AI_NAME} (`tail -f #{LOG}` to watch)\n".green
    else
      puts "Login failed for #{AI_NAME} (see #{LOG})".red
    end
  end

  def logged?(text_to_grep)
    return system("grep '#{text_to_grep}' #{LOG} > /dev/null")
  end

  def validate_connection
    result = IO.readlines(LOG)[1].chomp!
    return if result == "Connected to #{IP}."
    abort "Connection failed (result: #{result})".red
  end
end
