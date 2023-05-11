# frozen_string_literal: true

# String matching methods
module Matchers
  def shutdown_event_match
    /^-=> Reboot in/
  end

  def admin_cmd_match
    /^> #{ADMIN_NAME} tells you 'ADMIN: (.*?)'$/i
  end

  def direct_msg_match
    /^> (\S+) #{Regexp.union(DIRECT_MESSAGES)} '(.*?)'$/i
  end

  def room_msg_match
    /^([a-zA-Z]+) #{Regexp.union(ROOM_MESSAGES)} '#{AI_NAME},? (.*?)'$/i
  end

  def chan_msg_match
    /
      ^(#{Regexp.union(CHANNEL_PREFIXES)})\s
      ([a-zA-Z]+)\s#{Regexp.union(ROOM_MESSAGES)}\s
      '#{AI_NAME},?\s(.*?)'$
    /ix
  end

  def social_match
    /^> (.*?) (.*?)$/
  end

  def match_override(str)
    return false if str.nil?
    @overrides.each_key { |k| return @overrides[k] if str.match?(/#{k}/i) }
    return false
  end
end
