require 'net/http'
require 'json'
require_relative 'strings'

class ChatGPT
  def initialize(msg, hist, temp)
    history = hist.dup
    history << { "role": "user", "content": msg.force_encoding('UTF-8') }
    @uri = URI(GPT_API_URI)
    @headers = {
      'Content-Type': 'application/json',
      'Authorization': "Bearer #{GPT_API_KEY}"
    }
    @body = {
      'model': GPT_MODEL,
      'messages': history,
      'temperature': temp,
      'max_tokens': GPT_MAX_TOKENS
    }
  end

  def get_response
    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(@uri, @headers)
      request.body = @body.to_json
      response = http.request(request)
      log("DEBUG: #{response.body.to_s}", :info)
      return parse_reply(response.body.force_encoding('UTF-8'))
    rescue StandardError => e
      default_msg =
        "Oh no! Something went wrong and I can't connect to " \
        "ChatGPT. Sorry about that! I've logged the error so an " \
        "admin can investigate."
      limit_msg =
        "Sorry, I've exceeded my rate limit with ChatGPT. " \
        "Please try again in a little while."
      log("DEBUG: Error: #{e}", :error)
      return default_msg unless e.is_a?(Hash) && e.dig('error', 'message')
      return limit_msg if e.dig('error', 'message').start_with?("Rate limit")
      return default_msg
    end
  end

  private def parse_reply(json_response)
    response = JSON.parse(json_response)
    reply = response.dig('choices', 0, 'message', 'content')
    finish_reason = response.dig('choices', 0, 'finish_reason')
    reply += " ... [[[TRUNCATED]]]" if finish_reason == "length"
    return reply.gsub(/\n+/, ' ')
  end
end
