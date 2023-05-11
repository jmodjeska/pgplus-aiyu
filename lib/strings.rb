# frozen_string_literal: true

# String manipulation methods
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
    return [] if str.empty?
    chunks = []
    while str.length.positive?
      if str.length <= MESSAGE_CHUNK_SIZE
        chunks << str.strip
        break
      end
      c_size = find_chunk_size(str)
      chunk = str.slice!(0, c_size).strip
      if str[0] == ' '
        str[0] = ''
      elsif chunk[-1] != ' '
        c_size -= chunk.length - chunk.rindex(' ') - 1
        chunk = chunk.slice(0, chunk.rindex(' ')).strip
      end
      chunks << chunk
    end
    return chunks
  end

  def find_chunk_size(chunk)
    c_size = MESSAGE_CHUNK_SIZE
    while !['.', '!', '?'].include?(chunk[c_size - 1]) && c_size.positive?
      c_size -= 1
    end
    return c_size.zero? ? MESSAGE_CHUNK_SIZE : c_size
  end

  def format_numbered_list(arr)
    return arr unless arr.length > 1
    num = ''
    arr.each_with_index do |chunk, i|
      chunk.prepend(num)
      if chunk.match(/ (\d{1,2}\.)$/)
        num = "#{::Regexp.last_match(1)} "
        arr[i] = chunk[0...-num.length] unless arr[i + 1].nil?
      else
        num = ''
      end
    end
    return arr
  end

  def handle_truncated_response(str)
    if str.match(/\[\[\[TRUNCATED\]\]\]/)
      str = 'Sorry, there was more, but I truncated it due to length.'
    end
    return str
  end

  def force_utf_8(str)
    str = str.dup.force_encoding('UTF-8')
    str.encode!(
      'UTF-8', 'binary',
      invalid: :replace, undef: :replace, replace: ''
    )
    return str
  end

  def log(str, level)
    levels = {
      info: 'green',
      warn: 'magenta',
      error: 'red'
    }
    color = levels[level]
    File.write(LOG, "\n\n#{Time.now}: #{str}\n\n".send(color), mode: 'a+')
  end
end

# String monkey-patching to facilitate "text".color
class String
  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end

  def magenta
    "\e[35m#{self}\e[0m"
  end
end
