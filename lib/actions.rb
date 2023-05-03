module Actions
  private def clean_ansi(i)
    o = i.gsub(/\e\[([;\d]+)?m/, '').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip
    o.delete!("\r\n")
    o.delete!("^\u{0000}-\u{007F}")
    return o
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

  def get_stack(h)
    direct_msgs = CONFIG.dig('triggers', 'direct_msgs')
    stack_read_interval = CONFIG.dig('timings', 'stack_read_interval')
    stack = []
    if (Time.now.sec % stack_read_interval == 0)
      o = h.send('').split(/\r\n\e/)
      o.each do |line|
        line = clean_ansi(line)
        if (line[0] == ">") && (direct_msgs.any? { |s| line.include?(s) })
          p, msg = line.match(/^> (\S+).*?\'(.*?)\'$/).captures
          stack << [p, msg, :tell]
        end
      end
    end
    return stack
  end

  def tell(h, p, msg)
    chunks = msg.scan(/.{1,250}/)
    chunks.each do |chunk|
      h.send(".#{p} #{chunk}")
      sleep 1
    end
  end

  def process_callback(h, cmd, p, msg)
    case cmd
    when :tell
      tell(h, p, msg)
    else
      puts "Undefined callback command: #{cmd}"
    end
  end

  def clear_log(h, log)
    clear_log_interval = CONFIG.dig('timings', 'clear_log_interval')
    if (Time.now.min % clear_log_interval == 0) && (Time.now.sec % 60 == 0)
      File.truncate(log, 0)
    end
  end
end
