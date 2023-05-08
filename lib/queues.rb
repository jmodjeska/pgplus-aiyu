require_relative 'strings'

class Queues
  include Strings

  def initialize(h, profile, social)
    @h = h
    @profile = profile
    @social = social
    @cfg = get_config
    @q = []
    puts "-=> Queue manager initialized"
  end

  private def get_config
    return {
      :q_read_interval => CONFIG.dig('timings',  'queue_read_interval'),
      :chans => CONFIG.dig('triggers', 'channel_prefixes'),
      :chan_cmds => CONFIG.dig('triggers', 'channel_commands'),
      :prompt => CONFIG.dig('profiles', @profile, 'prompt'),
      :admin => CONFIG.dig('admin_access')
    }
  end

  private def add_item_to_queue(args = {})
    if (args[:p].nil?) || (args[:p].length < 2)
      args[:flags] << :invalid_player
    end
    @q << args
  end

  def build_queue
    flags = []
    if (Time.now.sec % @cfg[:q_read_interval] == 0)
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
        if line.match(/^> #{@cfg[:admin]} tells you 'ADMIN: (.*?)'$/)
          flags << :admin_command
          add_item_to_queue(p: @cfg[:admin], callback: $1, flags: flags)
          break
        end

        # Look for message and possible override
        message = parse_message(line, @profile)
        response = @social.get_override(message[:msg])
        response ? (flags << :override) : (flags << :ask_gpt)
        if message.keys.length == 3
          callback = nil
          case message[:loc]
          when :direct then callback = :tell
          when :room then callback = :say
          else #channel
            callback = @cfg[:chan_cmds][@cfg[:chans].index(message[:loc])]
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
