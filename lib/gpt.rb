# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative 'strings'

# Relay for ChatGPT API
class ChatGPT
  include Strings

  def initialize(msg, hist, temp)
    @temperature = temp
    @history = hist.dup
    @history << { "role": 'user', "content": msg.force_encoding('UTF-8') }
    @uri = URI(GPT_API_URI)
  end

  def chat
    response = send_http_request
    log("DEBUG: #{response.body}", :info)
    message = response.body.force_encoding('UTF-8')
    return parse_reply(message)
  rescue StandardError => e
    process_error(e)
  end

  private

  def headers
    return {
      'Content-Type': 'application/json',
      'Authorization': "Bearer #{GPT_API_KEY}"
    }
  end

  def body
    return {
      'model': GPT_MODEL,
      'messages': @history,
      'temperature': @temperature,
      'max_tokens': GPT_MAX_TOKENS
    }.to_json
  end

  def send_http_request
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(@uri, headers)
    request.body = body
    return http.request(request)
  rescue StandardError => e
    process_error(e)
  end

  def process_error(err)
    log("DEBUG: Error: #{err}", :error)
    if err.is_a?(Hash) && err.dig('error', 'message') &&
       err.dig('error', 'message').start_with?('Rate limit')
      return err_msg_string(:rate_limit)
    else
      return err_msg_string(:default)
    end
  end

  def err_msg_string(type)
    case type
    when :rate_limit
      return "Sorry, I've exceeded my rate limit with ChatGPT. " \
      'Please try again in a little while.'
    else
      return "Oh no! Something went wrong and I can't connect to " \
      "ChatGPT. Sorry about that! I've logged the error so an " \
      'admin can investigate.'
    end
  end

  def parse_reply(json_response)
    response = JSON.parse(json_response)
    reply = response.dig('choices', 0, 'message', 'content')
    finish_reason = response.dig('choices', 0, 'finish_reason')
    reply += ' ... [[[TRUNCATED]]]' if finish_reason == 'length'
    return reply.gsub(/\n+/, ' ')
  end
end
