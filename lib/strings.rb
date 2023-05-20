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
    return [str] if str.length < MESSAGE_CHUNK_SIZE
    chunks_arr = chunk_string(str)
    chunks_arr = format_numbered_list(chunks_arr) if chunks_arr.length > 1
    chunks_arr[-1] = handle_truncated_response(chunks_arr[-1])
    return chunks_arr
  end

  def chunk_string(text)
    return [text] if text.scan(/[^.!?]+[.!?]/).empty?
    sentences = text_to_sentences(text)
    chunks, chunk = sentences_to_chunks(sentences)
    chunks = words_to_chunks(chunks, chunk) if chunk.length.positive?
    return chunks
  end

  def text_to_sentences(text)
    sentences = text.split(/(?<=[.!?])\s+(?=\S)/)
    sentences.map! { |sentence| "#{sentence} " }
    return sentences
  end

  def sentences_to_chunks(sentences, chunk = '')
    chunks = []
    sentences.each do |sentence|
      if chunk.length + sentence.length <= MESSAGE_CHUNK_SIZE
        chunk += sentence
      else
        chunks << chunk
        chunk = sentence
      end
    end
    return chunks, chunk
  end

  def words_to_chunks(chunks, chunk)
    words = chunk.split
    while words.length.positive?
      line = ''
      while line.length < MESSAGE_CHUNK_SIZE && words.length.positive?
        line += "#{words.shift} "
      end
      chunks << line
    end
    return chunks
  end

  def format_numbered_list(arr, num = '')
    arr.each_with_index do |chunk, i|
      chunk.prepend(num)
      if chunk.match(/(\d{1,2}\.) $/)
        num = "#{::Regexp.last_match(1)} "
        arr[i] = chunk[0...-num.length] unless arr[i + 1].nil?
      else
        num = ''
      end
    end
    return arr
  end

  def handle_truncated_response(str)
    return MSG_TRUNCATED if str.match(/\[\[\[TRUNCATED\]\]\]/)
    return str
  end

  def force_utf_8(str)
    str = str.dup.force_encoding('UTF-8')
    str.encode!(
      'UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''
    )
    return str
  end

  def force_ascii_8(str)
    return str.dup.force_encoding('ASCII-8BIT')
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

# String monkey-patching to facilitate "string".color
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
