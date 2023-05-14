# frozen_string_literal: true

require 'yaml'
require_relative '../lib/matchers'
require_relative '../lib/constants'

ADMIN_NAME = 'Raindog'
AI_NAME = 'aiyu'

describe Matchers do
  include Matchers

  context 'when matching a shutdown signal from the talker' do
    it 'matches a shutdown signal' do
      input = '-=> Reboot in 15 seconds'
      result = input.match(shutdown_event_match)
      expect(result).to be_truthy
    end

    it "doesn't give a false positive shutdown signal" do
      input = '-=> Explode in 15 seconds'
      result = input.match(shutdown_event_match)
      expect(result).to be(nil)
    end
  end

  context 'when matching an admin command from a valid admin' do
    it 'matches an admin command from a valid admin' do
      input = "> Raindog tells you 'ADMIN: set temperature'"
      result = input.match(admin_cmd_match)
      expect(result).to be_truthy
    end

    it "doesn't match an admin command from a non-valid admin" do
      input = "> Monkey tells you 'ADMIN: set temperature'"
      result = input.match(shutdown_event_match)
      expect(result).to be(nil)
    end
  end

  context 'when matching a direct message (tell)' do
    it "matches a tell beginning with, 'tells you'" do
      input = "> Monkey tells you 'I believe you have my stapler'"
      result = input.match(direct_msg_match)
      expect(result).to be_truthy
    end

    it "matches a tell beginning with, 'asks of you'" do
      input = "> Monkey asks of you 'Excuse me sir, where are my pants?'"
      result = input.match(direct_msg_match)
      expect(result).to be_truthy
    end

    it "matches a tell beginning with, 'exclaims to you'" do
      input = "> Monkey exclaims to you 'I believe you have my stapler'"
      result = input.match(direct_msg_match)
      expect(result).to be_truthy
    end

    it "doesn't match a social" do
      input = '> Monkey farts in your general direction'
      result = input.match(direct_msg_match)
      expect(result).to be(nil)
    end

    it "doesn't match a room say" do
      input = "Monkey asks 'Let's close the things that close, okay'"
      result = input.match(direct_msg_match)
      expect(result).to be(nil)
    end

    it "doesn't match a remote" do
      input = '> Monkey pokes you in the boob'
      result = input.match(direct_msg_match)
      expect(result).to be(nil)
    end
  end

  context 'when matching a room message (say)' do
    it "matches a room message with 'say' directed at aiyu, with a comma" do
      input = "Giraffe says 'aiyu, my weiner is blue, please help me'"
      result = input.match(room_msg_match)
      expect(result).to be_truthy
    end

    it "matches a room message with 'say' directed at aiyu, without a comma" do
      input = "Giraffe says 'aiyu my weiner is blue, please help me'"
      result = input.match(room_msg_match)
      expect(result).to be_truthy
    end

    it "matches a room message with 'asks' directed at aiyu" do
      input = "Giraffe asks 'aiyu, why is my weiner is blue?'"
      result = input.match(room_msg_match)
      expect(result).to be_truthy
    end

    it "matches a room message with 'exclaims' directed at aiyu" do
      input = "Giraffe asks 'aiyu, my weiner is blue!'"
      result = input.match(room_msg_match)
      expect(result).to be_truthy
    end

    it "doesn't match a room message directed at someone else" do
      input = "Giraffe says 'Raindog, your weiner is also blue'"
      result = input.match(room_msg_match)
      expect(result).to be(nil)
    end
  end

  context 'when matching a channel message' do
    it 'matches a say on the main channel, directed at aiyu, with a comma' do
      input = "(UberChannel) Walrus says 'aiyu, bork bork bork bork bork'"
      result = input.match(chan_msg_match)
      expect(result).to be_truthy
    end

    it 'matches a say on the main channel, directed at aiyu, without a comma' do
      input = "(UberChannel) Walrus says 'aiyu bork bork bork bork bork'"
      result = input.match(chan_msg_match)
      expect(result).to be_truthy
    end

    it 'matches an ask on the main channel, directed at aiyu' do
      input = "(UberChannel) Walrus asks 'aiyu must you vacuum right now?'"
      result = input.match(chan_msg_match)
      expect(result).to be_truthy
    end

    it 'matches an exclaim on the main channel, directed at aiyu' do
      input = "(UberChannel) Po exclaims 'aiyu my hovercraft is full of eels!'"
      result = input.match(chan_msg_match)
      expect(result).to be_truthy
    end

    it "doesn't match a say on the main channel directed at someone else" do
      input = "(UberChannel) Walrus says 'Raindog, don't eat that; it's dirty'"
      result = input.match(chan_msg_match)
      expect(result).to be(nil)
    end
  end

  context 'when matching a social' do
    it 'matches a social directed at aiyu' do
      input = '> Frog whips out a rusty knife and stabs you in the arm!'
      result = input.match(social_match)
      expect(result).to be_truthy
    end

    it 'matches a remote' do
      # post-processing to determine if it's valid social happens downstream
      input = '> Frog looks at you kinda weird'
      result = input.match(social_match)
      expect(result).to be_truthy
    end
  end

  context 'when matching an override string' do
    it 'returns false for an empty string' do
      @overrides = YAML.load_file('config/overrides.yaml')
      result = match_override(nil, @overrides)
      expect(result).to be(false)
    end

    it 'matches a valid override string' do
      @overrides = YAML.load_file('config/overrides.yaml')
      input = 'Tell me about UberWorld please'
      result = match_override(input, @overrides)
      expect(result).to be_truthy
    end

    it 'returns false for a non-override string' do
      @overrides = YAML.load_file('config/overrides.yaml')
      input = 'Please tell me about Saskatchewan immediately'
      result = match_override(input, @overrides)
      expect(result).to be(false)
    end
  end
end
