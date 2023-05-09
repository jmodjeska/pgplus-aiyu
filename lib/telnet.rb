require 'net-telnet'
require_relative 'strings'

class ConnectTelnet
  def initialize
    puts "-=> Connecting to: #{TALKER_NAME}"
    @client = new_client
  end

  def new_client
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
      abort "Can't reach #{IP} at port #{PORT}\n".red
    rescue Errno::ECONNREFUSED => e
      abort "Connection refused to #{IP} at port #{PORT}.\n".red
    end

    # Validate connection
    result = IO.readlines(LOG)[1].chomp!
    unless result == "Connected to #{IP}."
      abort "Talker connection failed (result: #{result})".red
    end

    # Login + validation
    client.puts(AI_NAME)
    fork do
      sleep SLOWNESS_TOLERANCE
      if system("grep 'try again!' #{LOG} > /dev/null")
        puts "Talker login failed (password) for #{AI_NAME}".red
      elsif system("grep 'already logged on here' #{LOG} > /dev/null") ||
        system("grep 'Last logged in' #{LOG} > /dev/null")
        puts "-=> Talker login successful for #{AI_NAME} "\
          "(use `tail -f logs/output.log` to watch)\n".green
      else
        puts "Talker login failed for #{AI_NAME} (see #{LOG})".red
      end
    end
    client.cmd(PASSWORD)
    sleep 1 # Avoid exit before forked process completes
    return client
  end

  def send(cmd)
    stack = ''
    @client.cmd(cmd) { |o| stack << o }
    return stack
  end

  def write(cmd)
    @client.write(cmd)
  end

  def done
    @client.cmd("quit")
    sleep 0.1
    if system("grep 'Thank you for visiting' #{LOG} > /dev/null") ||
      system("grep 'Thanks for visiting' #{LOG} > /dev/null") ||
      system("grep 'please come again!' #{LOG} > /dev/null")
      log("Talker logout successful for #{AI_NAME}", :warn)
    else
      log("Disconnected ungracefully.", :error)
    end
  end
end
