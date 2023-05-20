# frozen_string_literal: true

require_relative 'strings'

# Callback handling
module Callbacks
  include Strings

  def do_callback(conn, task)
    return if report_invalid_player(task[:p])
    case task[:callback]
    when :tell then parse_tell_callback(conn, task)
    when :say then parse_room_say_callback(conn, task)
    when :social then parse_social_callback(conn, task)
    when *CHANNEL_COMMANDS then parse_channel_say_callback(conn, task)
    else log("#{ERR_UNDEF_CALLBACK} #{cmd}", :warn)
    end
  end

  def report_invalid_player(player)
    return false unless player.nil? || player.length < 2
    log("#{ERR_INVALID_PLAUER} #{player}", :warn)
  end

  def parse_tell_callback(conn, task)
    msg = task[:response] || task[:content]
    tell(conn, task[:p], msg)
  end

  def parse_room_say_callback(conn, task)
    msg = task[:response] || task[:content]
    room_or_channel_say(conn, task[:p], msg, 'say')
  end

  def parse_channel_say_callback(conn, task)
    msg = task[:response] || task[:content]
    room_or_channel_say(conn, task[:p], msg, task[:callback])
  end

  def parse_social_callback(conn, task)
    conn.send("#{task[:content]} #{task[:p]}")
  end
end
