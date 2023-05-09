require_relative 'strings'
require_relative 'version'

module Actions
  include Strings
  include Version

  def configure_talker_settings(h)
    toggle_pager(h, "unpaged")
    muffle_clock(h)
    h.send("see_gfx off")
    h.send("desc ^Y.*^N ChatGPT-connected AI bot v#{VERSION} ^R<3^N ^P^^_^^^N")
    h.send("url https://github.com/jmodjeska/pgplus-aiyu")
    h.send("main")
    send_greeting(h)
  end

  def process_callback(h, cmd, p, content)
    case cmd
    when :tell
      tell(h, p, content)
    when :say
      say_to_room_or_channel(h, p, content, 'say')
    when *CHANNEL_COMMANDS
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

  def send_greeting(h)
    c = ['bow', 'wave', 'hi5'].sample
    h.send(c)
  end

  def do_idle_command(h)
    if (Time.now.min % IDLE_INTERVAL == 0) && (Time.now.sec == 23)
      c = ['main', 'idle', 'look'].sample
      h.send(c)
    end
  end

  def log_time
    t = Time.now
    log("-=> Time: #{t}", :info) if (t.min == 38) && (t.sec == 43)
  end

  def clear_log(h, log)
    t = Time.now
    if (t.hour % CLEAR_LOG_INTERVAL == 0) && (t.min == 0) && (t.sec == 13)
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
    d_log = YAML.load_file(DISCLAIMER_LOG)
    return d_log.dig(p)
  end

  def process_disclaimer(h, p, msg)
    d_log = DISCLAIMER_LOG
    d = YAML.load_file(DISCLAIMER)
    if (msg.downcase == "i agree")
      File.write(d_log, "#{p}: '#{Time.now.to_s}'\n", mode: 'a+')
      d.dig('STAGE 2').each { |k, v| tell(h, p, v.gsub(/\s+/, ' ')) }
    else
      d.dig('STAGE 1').each { |k, v| tell(h, p, v.gsub(/\s+/, ' ')) }
    end
  end
end
