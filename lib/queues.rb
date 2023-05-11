# frozen_string_literal: true

require_relative 'strings'
require_relative 'matchers'

# Parse talker connection input and queue actionable tasks for processing
class Queues
  include Strings
  include Matchers

  def initialize(conn, social)
    @q = []
    @conn = conn
    @social = social
    @overrides = YAML.load_file('config/overrides.yaml')
    puts '-=> Queue manager initialized'
  end

  def build_queue
    return [] unless (Time.now.sec % Q_READ_INTERVAL).zero?
    read_lines_of_input.each do |line|
      case line
      when shutdown_event_match then @q << { flag: :shutdown_event }
      when admin_cmd_match then enqueue_admin_cmd($1)
      when direct_msg_match then enqueue_direct_msg($1, $2)
      when room_msg_match then enqueue_room_msg($1, $2)
      when chan_msg_match then enqueue_chan_msg($1, $2, $3)
      when social_match then enqueue_social($1, $2)
      end
    end
    return rotate_queue
  end

  private

  def read_lines_of_input
    lines = @conn.send('').split(/\r\n\e/)
    unless lines.map(&:valid_encoding?)
      log('Invalid encoding detected. Resetting queue.', :warn)
      return []
    end
    return lines.map! { |line| clean_ansi(line) }
  end

  def rotate_queue
    old_q = @q
    @q = []
    return old_q
  end

  # Enqueuers

  def enqueue_admin_cmd(cmd)
    @q << {
      p: ADMIN_NAME,
      callback: cmd,
      flag: :admin_cmd
    }
  end

  def enqueue_direct_msg(player, msg)
    message = {
      p: player,
      content: msg,
      callback: :tell
    }
    enqueue_message_or_override(message)
  end

  def enqueue_room_msg(player, msg)
    message = {
      p: player,
      content: msg,
      callback: :say
    }
    enqueue_message_or_override(message)
  end

  def enqueue_chan_msg(location, player, msg)
    message = {
      p: player,
      content: msg,
      callback: CHANNEL_COMMANDS[CHANNEL_PREFIXES.index(location)]
    }
    enqueue_message_or_override(message)
  end

  def enqueue_message_or_override(message)
    message[:flag] = match_override(message[:content]) ? :override : :chat_gpt
    message[:content] = match_override(message[:content]) || message[:content]
    @q << message
  end

  def enqueue_social(player, social)
    response_social = @social.respond_to_social(social)
    return if response_social.empty?
    @q << {
      p: player,
      content: response_social,
      callback: :social,
      flag: :social
    }
  end
end
