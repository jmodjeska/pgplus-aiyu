Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
require 'optimist'
require 'yaml'
include Actions
include QueueMgr

CONFIG = YAML.load_file('config/config.yaml')
LOG = CONFIG.dig('log')

##################################################
# CLI ARGUMENTS

o = Optimist::options do
  banner "\nSynopsis: ruby aiyu.rb\n\n"
  opt :profile, "Specify a talker profile",
    :default => CONFIG.dig('default_profile')
end

profile = o[:profile]
unless CONFIG.dig('profiles', profile)
  abort "Profile `#{profile}` does not exist."
end

##################################################
# MAIN LOOP

def main_loop(h, s, profile, social)
  shutdown_event = false
  sleep CONFIG.dig('timings', 'slowness_tolerance')
  toggle_pager(h, "unpaged")
  muffle_clock(h)
  h.send("see_gfx off")
  h.send("main")
  send_greeting(h)
  until (shutdown_event) do
    log_time
    do_idle_command(h)
    get_queue(h, profile, social).each do |queued|
      p, content, callback = queued
      if callback == :shutdown_event
        shutdown_event = true
        next
      end
      next if (p.nil?) || (p.length < 2)
      if callback == :do_social
        process_callback(h, callback, p, content)
      elsif check_disclaimer(p)
        history = s.get_history(p, callback)
        response = ChatGPT.new(content, history).get_response
        process_callback(h, callback, p, response)
        s.add_to_history(p, [content, response], callback)
      else
        process_disclaimer(h, p, content)
      end
    end
    clear_log(h, LOG)
    sleep 1
  end
  puts "-=> Detected shutdown event. Exiting.".magenta
  h.send('wave')
  h.done
end

##################################################
# RUNTIME

h = ConnectTelnet.new(profile)
social = Social.new(profile)
s = Sessions.new

begin
  main_loop(h, s, profile, social)
rescue Net::ReadTimeout => e
  puts "\n-=> Timed out waiting for talker response. Forcing reconnect.".red
  h.done
  h = ConnectTelnet.new(profile)
  main_loop(h, s, profile, social)
  h.send("whistle")
end
