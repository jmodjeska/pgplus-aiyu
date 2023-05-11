# frozen_string_literal: true

require 'time'
require_relative 'strings'

# Session manager. Session history follows a player in the case of a direct
# msg (tell); else it treats the main room or specified channel as a
# shared group session.
class Sessions
  include Strings
  attr_accessor :temp

  def initialize
    @session = {}
    @history = {}
    @recons = []
    @temp = DEFAULT_TEMPERATURE
    puts '-=> Session manager initialized'
  end

  def expired(player)
    return (@session[player] + ONE_HOUR * SESSION_DURATION) < Time.now
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
    hist = command == :tell ? player : command
    if @session.key?(hist) && !expired(hist) && @history.key?(hist)
      @session[hist] = Time.now
      return @history[hist]
    elsif @session.key?(hist)
      @session.delete(hist)
      @history.delete(hist)
    end
    @session[hist] = Time.now
    return []
  end

  def read_history(str)
    return @history[str]
  end

  def append(player, msgset, command)
    history_scope = command == :tell ? player : command
    unless @history.key?(history_scope)
      seed_msgset = [{ "role": 'system', "content": "#{GPT_ROLE} #{AI_NAME}." }]
      @history[history_scope] = seed_msgset
    end
    @history[history_scope].concat encode_msgset(msgset)
    return @history[history_scope]
  end
end
