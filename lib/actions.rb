# frozen_string_literal: true

require_relative 'strings'

# Metadata output and direct actions Aiyu can perform in the talker
module Actions
  include Strings

  def configure_player_settings(conn)
    sleep LOGIN_TOLERANCE
    toggle_pager(conn, 'unpaged')
    conn.send('see_gfx off')
    conn.send("desc #{DESCRIPTION}")
    conn.send("url #{URL}")
    conn.send('main')
    send_greeting(conn)
  end

  def log_time
    t = Time.now
    return unless (t.min == LOG_TIME_MINS) && (t.sec == LOG_TIME_SECS)
    log("-=> Time: #{t}", :info)
  end

  def clear_log
    t = Time.now
    if (t.hour % CLEAR_LOG_INTERVAL).zero? &&
       t.min.zero? && (t.sec == CLEAR_LOG_SECS)
      File.truncate(LOG, 0)
    end
  end

  def toggle_pager(conn, desired_state)
    2.times do
      o = clean_ansi(conn.send('nopager')).lines[0]
      state = o.match?('You will not') ? 'unpaged' : 'paged'
      return if state == desired_state
    end
  end

  def send_greeting(conn)
    cmd = %w[bow wave hi5].sample
    conn.send(cmd)
  end

  def do_idle_command(conn)
    t = Time.now
    return unless (t.min % IDLE_INTERVAL).zero? && (t.sec == IDLE_CMD_SECS)
    cmd = %w[main idle look].sample
    conn.send(cmd)
  end

  def tell(conn, player, msg)
    msg = msg.dup.force_encoding('ASCII-8BIT')
    chunks = process_message(msg)
    chunks.each do |chunk|
      conn.send(".#{player} #{chunk}")
      sleep COMMAND_PACING
    end
  end

  def room_or_channel_say(conn, player, msg, cmd)
    msg = msg.dup.force_encoding('ASCII-8BIT')
    chunks = process_message(msg)
    chunks[0][0] = chunks[0][0].downcase
    conn.send("#{cmd} #{player}, #{chunks[0]}")
    chunks.drop(1).each do |chunk|
      conn.send("#{cmd} #{chunk}")
      sleep COMMAND_PACING
    end
  end

  def disclaim(conn, player, msg, stage = 1)
    d = YAML.load_file(DISCLAIMER)
    if msg.downcase == 'i agree'
      File.write(DISCLAIMER_LOG, "#{player}: '#{Time.now}'\n", mode: 'a+')
      stage = 2
    end
    d["STAGE #{stage}"].each { |_k, v| tell(conn, player, v.gsub(/\s+/, ' ')) }
  end
end
