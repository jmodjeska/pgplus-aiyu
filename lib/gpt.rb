require 'net/http'
require 'json'
require_relative 'strings'

class ChatGPT
  def initialize(msg, history)
    @msg = msg.force_encoding('UTF-8')
    @history = history.dup
  end

  def get_response
    @history << { "role": "user", "content": @msg }

    uri = URI('https://api.openai.com/v1/chat/completions')
    headers = {
      'Content-Type': 'application/json',
      'Authorization': "Bearer #{ENV['OPENAI_API_KEY']}"
    }
    body = {
      'model': 'gpt-3.5-turbo',
      'messages': @history,
      'temperature': 0.8,
      'max_tokens': 250
    }

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body.to_json
      response = http.request(request)
      log("DEBUG: #{response.body.to_s}", :info)
      resp = JSON.parse(response.body.force_encoding('UTF-8'))
      reply = resp.dig('choices', 0, 'message', 'content')
      finish_reason = resp.dig('choices', 0, 'finish_reason')
      reply += " ... [[[TRUNCATED]]]" if finish_reason == "length"
      return reply.gsub(/\n+/, ' ')

    rescue StandardError => e
      log("DEBUG: Error: #{e}", :error)
      if e.is_a?(Hash) && e.dig('error', 'message')
        if e.dig('error', 'message').start_with?("Rate limit")
          return "Sorry, I've exceeded my rate limit with ChatGPT. "\
            "Please try again in a little while."
        end
      else
        return "Oh no! Something went wrong and I can't connect to "\
          "ChatGPT. Sorry about that! I've logged the error so an "\
          "admin can investigate."
      end
    end
  end
end
