# frozen_string_literal: true

require 'time'
require_relative 'strings'

# Session manager. Session history follows a player in the case of a direct
# msg (tell); else it treats the main room or specified channel as a
# shared group session.
class Sessions
  include Strings
  attr_accessor :temp
  attr_accessor :session

  def initialize
    @session = {}
    @history = {}
    @recons = []
    @temp = DEFAULT_TEMP
    puts '-=> Session manager initialized'
  end

  def expired(scope)
    return (@session[scope] + ONE_HOUR * SESSION_DURATION) < Time.now
  end

  def seed_msgset
    return [{
      "role": 'system',
      "content": "#{GPT_ROLE} #{AI_NAME}."
    }]
  end

  def encode_msgset(msgset)
    o, i = msgset
    [o, i].each { |str| force_utf_8(String.new(str)) }
    return [
      { "role": 'user', "content": o },
      { "role": 'assistant', "content": i }
    ]
  end

  def update_temp(temp)
    return @temp = temp.to_f
  end

  def recons_available
    return true if @recons.empty?
    last_recon = @recons.max
    if (Time.now - last_recon) > ONE_HOUR
      @recons = []
      return true
    end
    return @recons.count { |r| (Time.now - r) < ONE_HOUR } < MAX_RECONNECTS
  end

  def log_recon
    return @recons << Time.now
  end

  def get_history(player, command)
    scope = command == :tell ? player : command
    if @session.key?(scope) && !expired(scope) && @history.key?(scope)
      @session[scope] = Time.now
      return @history[scope]
    end
    reset_session_and_history(scope)
    return []
  end

  def reset_session_and_history(scope)
    @history.delete(scope)
    @session[scope] = Time.now
  end

  def read_history(str)
    return @history[str]
  end

  def append(player, msgset, command)
    scope = command == :tell ? player : command
    @history[scope] = seed_msgset unless @history.key?(scope)
    @history[scope].concat encode_msgset(msgset)
    return @history[scope]
  end
end
