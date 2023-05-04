require 'net-telnet'

private def cfg(profile, key)
  return CONFIG.dig('profiles', profile, key)
end

class ConnectTelnet
  attr_reader :prompt, :ip

  def initialize(profile)
    @profile = profile
    @username = cfg(@profile, 'username')
    @ip = cfg(@profile, 'ip')
    @port = cfg(@profile, 'port')
    @name = cfg(@profile, 'talker_name')
    @prompt = cfg(@profile, 'prompt')
    puts "-=> Connecting to: #{@name}"
    @client = new_client
  end

  def new_client
    File.truncate(LOG, 0) if File.exist?(LOG)
    begin
      client = Net::Telnet::new(
        "Host" => @ip,
        "Port" => @port,
        "Prompt" => /#{@prompt} \z/n,
        "Binmode" => true,
        "Telnetmode" => true,
        "Timeout" => 3,
        "Output_log" => LOG,
        "Dump_Log" => true,
        "Debug_Output" => true
      )
    rescue Errno::EHOSTUNREACH, Net::OpenTimeout => e
      abort "Can't reach #{@ip} at port #{@port}\n"
    rescue Errno::ECONNREFUSED => e
      abort "Connection refused to #{@ip} at port #{@port}. "\
        "Is the talker running?\n"
    end

    # Validate connection
    result = IO.readlines(LOG)[1].chomp!
    unless result == "Connected to #{@ip}."
      abort "Talker connection failed (result: #{result})"
    end

    # Login + validation
    client.puts(@username)
    fork do
      sleep 1
      if system("grep 'try again!' #{LOG} > /dev/null") then
        puts "Talker login failed (password) for #{@username}"
      elsif system("grep 'already logged on here' #{LOG} > /dev/null")
        puts "Talker login successful for #{@username} "\
          "(NOTE: user was already logged in)"
        client.puts('')
      elsif system("grep 'Last logged in' #{LOG} > /dev/null")
        puts "Talker login successful for #{@username} "\
          "(use `tail -f logs/output.log` to follow along live)"
      else
        puts "Talker login failed for #{@username} (see #{LOG})"
      end
    end
    client.cmd(cfg(@profile, 'password'))
    sleep 1 # Avoid exit before forked process completes
    return client
  end

  def send(cmd)
    stack = ''
    @client.cmd(cmd) { |o| stack << o }
    return stack
  end

  def done
    @client.cmd("quit")
    sleep 0.1
    if system("grep 'Thanks for visiting' #{LOG} > /dev/null") then
      puts "-=> Talker logout successful for #{@username}"
    end
    puts "\n"
  end
end
