require_relative 'strings'

class Queues
  include Strings

  def initialize(h, social)
    @h, @social, @q = h, social, []
    puts "-=> Queue manager initialized"
  end

  def build_queue
    return [] unless (Time.now.sec % Q_READ_INTERVAL) == 0
    o = @h.send('').split(/\r\n\e/)
    unless o.map(&:valid_encoding?)
      log("Invalid encoding detected. Resetting queue.", :warn)
      return []
    end
    o.each do |line|
      line = clean_ansi(line)
      # Match shutdown event or admin commands
      if line.match(/^\-\=\> Reboot in/)
        @q << { flag: :shutdown_event }
        break
      elsif line.match(/^> #{ADMIN_NAME} tells you 'ADMIN: (.*?)'$/)
        @q << { p: ADMIN_NAME, callback: $1, flag: :admin_command }
        break
      end
      # Look for message, override, or social
      message = parse_message(line)
      override_response = @social.get_override(message[:msg])
      flag = override_response ? :override : :chat_gpt
      if message.keys.length == 3
        callback = get_callback_by_location(message[:loc])
        @q << {
          p: message[:p],
          content: message[:msg],
          callback: callback,
          flag: flag,
          override_response: override_response
        }
      else
        s = @social.parse(line)
        @q << {
          p: s[:p],
          content: s[:soc],
          callback: :do_social,
          flag: :do_social
         } unless s.empty?
      end
    end
    old_q = @q
    @q = []
    return old_q
  end

  private def get_callback_by_location(loc)
    case loc
    when :direct then return :tell
    when :room then return :say
    else #channel
      return CHANNEL_COMMANDS[CHANNEL_PREFIXES.index(loc)]
    end
  end

  private def parse_message(str)
    msgs = {}
    # direct message
    if (str[0] == ">") && (DIRECT_MESSAGES.any? { |s| str.include?(s) })
      msgs[:p], msgs[:msg] = str.match(/^> (\S+).*?\'(.*?)\'$/).captures
      msgs[:loc] = :direct
    # room message
    elsif str.match(/^([a-zA-Z]+)\s
      #{Regexp.union(ROOM_MESSAGES)}\s'#{AI_NAME}[,]?\s(.*?)'$/ix)
      msgs[:p], msgs[:msg] = $1, $2
      msgs[:loc] = :room
    # channel message
    elsif str.match(/^(#{Regexp.union(CHANNEL_PREFIXES)})\s([a-zA-Z]+)\s
      #{Regexp.union(ROOM_MESSAGES)}\s'#{AI_NAME}[,]?\s(.*?)'$/ix)
      msgs[:loc], msgs[:p], msgs[:msg] = $1, $2, $3
    end
    return msgs
  end
end
