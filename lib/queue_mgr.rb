require_relative 'strings'

module QueueMgr
  include Strings

  def get_queue(h, profile, socials)
    q_read_interval  = CONFIG.dig('timings',  'queue_read_interval')
    channel_prefixes = CONFIG.dig('triggers', 'channel_prefixes')
    channel_commands = CONFIG.dig('triggers', 'channel_commands')
    q = []
    if (Time.now.sec % q_read_interval == 0)
      o = h.send('').split(/\r\n\e/)
      unless o.map(&:valid_encoding?)
        puts "-=> Invalid encoding detected. Resetting queue."
        return q
      end
      o.each do |line|
        line = clean_ansi(line)
        puts line
        msgs = parse_message(line, profile)
        if msgs.keys.length == 3
          case msgs[:loc]
          when :direct
            q << [msgs[:p], msgs[:msg], :tell]
          when :room
            q << [msgs[:p], msgs[:msg], :say]
          else #channel
            q << [msgs[:p], msgs[:msg],
              channel_commands[channel_prefixes.index(msgs[:loc])]]
          end
        else
          social = socials.parse(line)
          unless social.empty?
            q << [social[:p], social[:soc], :do_social]
          end
        end
      end
    end
    return q
  end
end
