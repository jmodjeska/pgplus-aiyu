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

def main_loop(h, s, profile, socials)
  shutdown_event = false
  sleep CONFIG.dig('timings', 'slowness_tolerance')
  toggle_pager(h, "unpaged")
  muffle_clock(h)
  h.send("main")
  until (shutdown_event) do
    do_idle_command(h)
    get_queue(h, profile, socials).each do |queued|
      p, content, callback = queued
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
end

##################################################
# RUNTIME

h = ConnectTelnet.new(profile)
socials = Socials.new(profile)
s = Sessions.new

begin
  main_loop(h, s, profile, socials)
rescue Net::ReadTimeout => e
  puts "\n-=> Timed out waiting for talker response. Forcing reconnect."
  h.done
  h = ConnectTelnet.new(profile)
  main_loop(h, s, profile, socials)
  h.send("whistle")
end
