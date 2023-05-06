require_relative 'strings'

module Actions
  include Strings

  def process_callback(h, cmd, p, msg)
    case cmd
    when :tell
      tell(h, p, msg)
    when :say
      say_to_room_or_channel(h, p, msg, 'say')
    when *CONFIG.dig('triggers', 'channel_commands')
      say_to_room_or_channel(h, p, msg, cmd)
    else
      puts "Undefined callback command: #{cmd}"
    end
  end

  def toggle_pager(h, desired_state)
    2.times do
      o = clean_ansi(h.send('nopager')).lines[0]
      state = o.match?("You will not") ? 'unpaged' : 'paged'
      return true if state == desired_state
    end
    return false
  end

  def do_idle_command(h)
    idle_interval = CONFIG.dig('timings', 'idle_interval')
    if (Time.now.min % idle_interval == 0) && (Time.now.sec % 60 == 0)
      c = ['main', 'idle', 'look'].sample
      h.send(c)
    end
  end

  def tell(h, p, msg)
    chunks = split_string(msg)
    chunks.each do |chunk|
      h.send(".#{p} #{chunk}")
      sleep 1
    end
  end

  def say_to_room_or_channel(h, p, msg, cmd)
    chunks = split_string(msg)
    chunks.each_with_index do |chunk, i|
      if i == 0
        chunk[0] = chunk[0].downcase
        h.send("#{cmd} #{p}, #{chunk}")
      else
        h.send("#{cmd} #{chunk}")
      end
      sleep 1
    end
  end

  def check_disclaimer(p)
    d_log = YAML.load_file(CONFIG.dig('disclaimer_log'))
    return d_log.dig(p)
  end

  def process_disclaimer(h, p, msg)
    puts msg.downcase
    d_log = CONFIG.dig('disclaimer_log')
    disclaimer = YAML.load_file(CONFIG.dig('disclaimer'))
    if (msg.downcase == "i agree")
      File.write(d_log, "#{p}: '#{Time.now.to_s}'\n", mode: 'a+')
      tell(h, p, disclaimer.dig('STAGE 2').gsub(/\s+/, ' '))
    else
      tell(h, p, disclaimer.dig('STAGE 1a').gsub(/\s+/, ' '))
      tell(h, p, disclaimer.dig('STAGE 1b').gsub(/\s+/, ' '))
    end
  end

  def clear_log(h, log)
    clear_log_interval = CONFIG.dig('timings', 'clear_log_interval')
    if (Time.now.min % clear_log_interval == 0) && (Time.now.sec % 60 == 0)
      File.truncate(log, 0)
    end
  end
end
