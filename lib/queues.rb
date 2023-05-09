require_relative 'strings'

class Queues
  include Strings

  def initialize(h, social)
    @h = h
    @social = social
    @q = []
    puts "-=> Queue manager initialized"
  end

  private def add_item_to_queue(args = {})
    if (args[:p].nil?) || (args[:p].length < 2)
      args[:flags] << :invalid_player
    end
    @q << args
  end

  def build_queue
    flags = []
    if (Time.now.sec % Q_READ_INTERVAL == 0)
      o = @h.send('').split(/\r\n\e/)
      unless o.map(&:valid_encoding?)
        log("Invalid encoding detected. Resetting queue.", :warn)
        return []
      end
      o.each do |line|
        line = clean_ansi(line)

        # Look for shutdown signal if >15 seconds notice
        if line.match(/^\-\=\> Reboot in/)
          flags << :shutdown_event
          add_item_to_queue(flags: flags)
          break
        end

        # Look for admin command
        if line.match(/^> #{ADMIN_NAME} tells you 'ADMIN: (.*?)'$/)
          flags << :admin_command
          add_item_to_queue(p: ADMIN_NAME, callback: $1, flags: flags)
          break
        end

        # Look for message and possible override
        message = parse_message(line)
        response = @social.get_override(message[:msg])
        response ? (flags << :override) : (flags << :ask_gpt)
        if message.keys.length == 3
          callback = nil
          case message[:loc]
          when :direct then callback = :tell
          when :room then callback = :say
          else #channel
            callback = CHANNEL_COMMANDS[CHANNEL_PREFIXES.index(message[:loc])]
          end
          add_item_to_queue(p: message[:p], content: message[:msg],
            callback: callback, flags: flags, override_response: response)
        # Look for social
        else
          s = @social.parse(line)
          add_item_to_queue(p: s[:p], content: s[:soc],
            callback: :do_social, flags: flags) unless s.empty?
        end
      end
    end
    old_q = @q
    @q = []
    return old_q
  end
end
