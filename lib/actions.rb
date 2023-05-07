require_relative 'strings'

module Actions
  include Strings

  def process_callback(h, cmd, p, content)
    case cmd
    when :tell
      tell(h, p, content)
    when :say
      say_to_room_or_channel(h, p, content, 'say')
    when *CONFIG.dig('triggers', 'channel_commands')
      say_to_room_or_channel(h, p, content, cmd)
    when :do_social
      h.send("#{content} #{p}")
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

  def muffle_clock(h)
    2.times do
      o = clean_ansi(h.send('muffle clock')).lines[0]
      return true if o.match?("You are now ignoring")
    end
    return false
  end

  def do_idle_command(h)
    idle_interval = CONFIG.dig('timings', 'idle_interval')
    if (Time.now.min % idle_interval == 0) && (Time.now.sec == 23)
      c = ['main', 'idle', 'look'].sample
      h.send(c)
    end
  end

  def log_time
    t = Time.now
    puts "-=> Time: #{t}".green if (t.min == 32) && (t.sec == 43)
  end

  def clear_log(h, log)
    clear_log_interval = CONFIG.dig('timings', 'clear_log_interval')
    if (Time.now.hour % clear_log_interval == 0) &&
      (Time.now.min % 60 == 0) && (Time.now.sec == 13)
      File.truncate(log, 0)
    end
  end

  def tell(h, p, msg)
    msg.force_encoding('ASCII-8BIT')
    chunks = chunk_string(msg)
    chunks.each do |chunk|
      h.send(".#{p} #{chunk}")
      sleep 1
    end
  end

  def say_to_room_or_channel(h, p, msg, cmd)
    msg.force_encoding('ASCII-8BIT')
    chunks = chunk_string(msg)
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
    d_log = CONFIG.dig('disclaimer_log')
    d = YAML.load_file(CONFIG.dig('disclaimer'))
    if (msg.downcase == "i agree")
      File.write(d_log, "#{p}: '#{Time.now.to_s}'\n", mode: 'a+')
      d.dig('STAGE 2').each { |k, v| tell(h, p, v.gsub(/\s+/, ' ')) }
    else
      d.dig('STAGE 1').each { |k, v| tell(h, p, v.gsub(/\s+/, ' ')) }
    end
  end
end
