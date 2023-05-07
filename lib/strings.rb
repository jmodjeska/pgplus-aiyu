module Strings

  def clean_ansi(str)
    o = str.gsub(/\e\[([;\d]+)?m/, '')
    o = o.gsub(/\n|\s+/, ' ').strip
    o = o.gsub(/\[m/, '')
    o.delete!("\r\n")
    o.delete!("^\u{0000}-\u{007F}")
    return o
  end

  def chunk_string(str)
    chunks = []
    while str.length > 0
      if str.length <= 250
        chunks << str.strip
        break
      end
      chunk_size = 250
      chunk_size -= 1 while ![".", "!", "?"].
        include?(str[chunk_size - 1]) && chunk_size > 0
      chunk_size = 250 if chunk_size == 0
      chunk = str.slice!(0, chunk_size).strip
      if str[0] == " "
        str[0] = ""
      elsif chunk[-1] != " "
        chunk_size -= chunk.length - chunk.rindex(" ") - 1
        chunk = chunk.chunk(0, chunk.rindex(" ")).strip
      end
      chunks << chunk
    end
    format_numbered_list(chunks)
  end

  def format_numbered_list(chunks)
    num = ""
    if chunks.length > 1
      chunks.each_with_index do |chunk, i|
        chunk.prepend(num)
        if chunk.match(/ (\d{1,2}\.)$/)
          num = "#{$1} "
          chunks[i] = chunk[0...-(num.length)] unless chunks[i+1].nil?
        else
          num = ""
        end
      end
    end
    handle_truncated_response(chunks)
  end

  def handle_truncated_response(chunks)
    if chunks[-1].match(/\[\[\[TRUNCATED\]\]\]/)
      chunks[-1].delete!('[[[TRUNCATED]]]')
      trunc_text = "Sorry, there was more, but I had to truncate it due "\
        "to excessive length."
      chunks << trunc_text
    end
    return chunks
  end

  def parse_message(str, profile)
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
      #{Regexp.union(room_msgs)}\s'#{name}[,]?\s(.*?)'$/ix)
      msgs[:p], msgs[:msg] = $1, $2
      msgs[:loc] = :room
    # channel message
    elsif str.match(/^(#{Regexp.union(channel_prefixes)})\s([a-zA-Z]+)\s
      #{Regexp.union(room_msgs)}\s'#{name}[,]?\s(.*?)'$/ix)
      msgs[:loc], msgs[:p], msgs[:msg] = $1, $2, $3
    end
    return msgs
  end
end

class String
  def red;      "\e[31m#{self}\e[0m" end
  def green;    "\e[32m#{self}\e[0m" end
  def blue;     "\e[34m#{self}\e[0m" end
  def magenta;  "\e[35m#{self}\e[0m" end
  def cyan;     "\e[36m#{self}\e[0m" end
  def bold;     "\e[1m#{self}\e[22m" end
end
