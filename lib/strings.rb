module Strings

  def clean_ansi(str)
    o = str.gsub(/\e\[([;\d]+)?m/, '').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip
    o.delete!("\r\n")
    o.delete!("^\u{0000}-\u{007F}")
    return o
  end

  def split_string(str)
    chunks = []
    while str.length > 0
      if str.length <= 250
        chunks << str.strip
        break
      end
      slice_size = 250
      slice_size -= 1 while ![".", "!", "?"].
        include?(str[slice_size - 1]) && slice_size > 0
      slice_size = 250 if slice_size == 0
      slice = str.slice!(0, slice_size).strip
      if str[0] == " "
        str[0] = ""
      elsif slice[-1] != " "
        slice_size -= slice.length - slice.rindex(" ") - 1
        slice = slice.slice(0, slice.rindex(" ")).strip
      end
      chunks << slice
    end
    chunks
  end

  def parse_messages(str, profile)
    msgs = {}
    name = CONFIG.dig('profiles', profile, 'username')
    direct_msgs = CONFIG.dig('triggers', 'direct_msgs')
    room_msgs = CONFIG.dig('triggers', 'room_msgs')
    channel_prefixes = CONFIG.dig('triggers', 'channel_prefixes')
    # direct message
    if (str[0] == ">") && (direct_msgs.any? { |s| str.include?(s) })
      msgs[:p], msgs[:msg] = str.match(/^> (\S+).*?\'(.*?)\'$/).captures
      msgs[:loc] = :direct
    # room message
    elsif str.match(/^([a-zA-Z]+)\s
      #{Regexp.union(room_msgs)}\s'#{name},\s(.*?)'$/ix)
      msgs[:p], msgs[:msg] = $1, $2
      msgs[:loc] = :room
    # channel message
    elsif str.match(/^(#{Regexp.union(channel_prefixes)})\s([a-zA-Z]+)\s
      #{Regexp.union(room_msgs)}\s'#{name},\s(.*?)'$/ix)
      msgs[:loc], msgs[:p], msgs[:msg] = $1, $2, $3
    end
    return msgs
  end
end
