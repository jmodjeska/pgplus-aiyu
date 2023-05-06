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

def main_loop(h, s, profile)
  sleep CONFIG.dig('timings', 'slowness_tolerance')
  shutdown_event = false
  until (shutdown_event) do
    do_idle_command(h)
    get_queue(h, profile).each do |queued|
      p, msg, callback = queued
      if check_disclaimer(p)
        history = s.get_history(p, callback)
        response = ChatGPT.new(msg, history).get_response
        process_callback(h, callback, p, response)
        s.add_to_history(p, [msg, response], callback)
      else
        process_disclaimer(h, p, msg)
      end
    end
    clear_log(h, LOG)
    sleep 1
  end
end

##################################################
# RUNTIME

h = ConnectTelnet.new(profile)
s = Sessions.new
toggle_pager(h, "unpaged")
muffle_clock(h)
h.send("main")

begin
  main_loop(h, s, profile)
rescue Net::ReadTimeout => e
  puts "\n-=> Timed out waiting for talker response."
  h.done
end
