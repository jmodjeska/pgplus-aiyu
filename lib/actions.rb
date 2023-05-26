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
    conn.send(GREETING_SOCIALS.sample)
  end

  def do_idle_command(conn)
    t = Time.now
    return unless (t.min % IDLE_INTERVAL).zero? && (t.sec == IDLE_CMD_SECS)
    conn.send(IDLE_COMMANDS.sample)
  end

  def harass_idle_person(conn)
    t = Time.now
    return unless (t.min % HARASS_INTERVAL).zero? && (t.sec == HARASS_CMD_SECS)
    i = check_most_idle(conn)
    conn.send("#{HARASS_SOCIALS.sample} #{i}") unless i.nil?
  end

  def check_most_idle(conn)
    idle = clean_ansi(conn.send('idle'))
    return unless idle.match(/(\d+) people here/) || $1 == 1
    i = idle.scan(/(\d+:\d+:\d+:\d+) - (.*?) /).to_h
    OTHER_ROBOTS.each { |r| i.delete_if { |_k, v| v.downcase == r.downcase } }
    return i.max_by { |k, _v| k }[1]
  end

  def tell(conn, player, msg)
    chunks = process_message(force_ascii_8(msg))
    chunks.each do |chunk|
      conn.send(".#{player} #{chunk}")
      sleep COMMAND_PACING
    end
  end

  def room_or_channel_say(conn, player, msg, cmd)
    chunks = process_message(force_ascii_8(msg))
    chunks[0][0] = chunks[0][0].downcase
    conn.send("#{cmd} #{player}, #{chunks[0]}")
    chunks.drop(1).each do |chunk|
      conn.send("#{cmd} #{chunk}")
      sleep COMMAND_PACING
    end
  end

  def disclaim(conn, player, msg, stage = 1)
    if msg.downcase == 'i agree'
      File.write(DISCLAIMER_LOG, "#{player}: '#{Time.now}'\n", mode: 'a+')
      stage = 2
    end
    d = YAML.load_file(DISCLAIMER)
    d["STAGE #{stage}"].each { |_k, v| tell(conn, player, v.gsub(/\s+/, ' ')) }
  end
end
