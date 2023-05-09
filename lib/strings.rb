module Strings
  def clean_ansi(str)
    o = str.gsub(/\e\[([;\d]+)?m/, '')
    o = o.gsub(/\n|\s+/, ' ').strip
    o = o.gsub(/\[m/, '')
    o.delete!("\r\n")
    o.delete!("^\u{0000}-\u{007F}")
    return o
  end

  def process_message(str)
    chunks_array = chunk_string(str)
    chunks_array = format_numbered_list(chunks_array)
    chunks_array[-1] = handle_truncated_response(chunks_array[-1])
    return chunks_array
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
        chunk = chunk.slice(0, chunk.rindex(" ")).strip
      end
      chunks << chunk
    end
    return chunks
  end

  def format_numbered_list(arr)
    num = ""
    return arr unless arr.length > 1
    arr.each_with_index do |chunk, i|
      chunk.prepend(num)
      if chunk.match(/ (\d{1,2}\.)$/)
        num = "#{$1} "
        arr[i] = chunk[0...-(num.length)] unless arr[i+1].nil?
      else
        num = ""
      end
    end
    return arr
  end

  def handle_truncated_response(str)
    if str.match(/\[\[\[TRUNCATED\]\]\]/)
      str = "Sorry, there was more, but I truncated it due to length."
    end
    return str
  end

  def valid_player(p)
    return !(p.nil? || p.length < 2)
  end

  def log(str, level)
    levels = {
      :info => 'green',
      :warn => 'magenta',
      :error => 'red'
    }
    color = levels[level]
    File.write(LOG, "\n\n#{Time.now}: #{str}\n\n".send(color), mode: 'a+')
  end
end

class String
  def red;      "\e[31m#{self}\e[0m" end
  def green;    "\e[32m#{self}\e[0m" end
  def magenta;  "\e[35m#{self}\e[0m" end
end
