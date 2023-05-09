Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
require 'optimist'
require 'yaml'
include Actions
include Admin
include SystemOps

CONFIG          = YAML.load_file(CONFIG_FILE)
AI_NAME         = CONFIG.dig('ai_name')
ADMIN_NAME      = CONFIG.dig('admin_access')
DEFAULT_PROFILE = CONFIG.dig('default_profile')

##################################################
# CLI ARGUMENTS

o = Optimist::options do
  banner "\nSynopsis: ruby aiyu.rb\n\n"
  opt :profile, "Specify a talker profile",
    :default => DEFAULT_PROFILE
end

if CONFIG.dig('profiles', o[:profile])
  SOCIALS_DIR = CONFIG.dig('profiles', o[:profile], 'socials_dir')
  TALKER_NAME = CONFIG.dig('profiles', o[:profile], 'talker_name')
  PASSWORD    = CONFIG.dig('profiles', o[:profile], 'password')
  PROMPT      = CONFIG.dig('profiles', o[:profile], 'prompt')
  PORT        = CONFIG.dig('profiles', o[:profile], 'port')
  IP          = CONFIG.dig('profiles', o[:profile], 'ip')
else
  abort "Profile `#{o[:profile]}` does not exist."
end

##################################################
# MAIN LOOP

def main_loop(h, session, social, q)
  shutdown_event = false
  sleep SLOWNESS_TOLERANCE
  configure_talker_settings(h)
  until (shutdown_event) do
    log_time
    do_idle_command(h)
    clear_log(h, LOG)
    q.build_queue.each do |qi|
      p, callback, flags = qi[:p], qi[:callback], qi[:flags]
      content = qi[:content]
      if flags.include? :shutdown_event
        shutdown_event = true
        break
      elsif flags.include? :admin_command
        admin_do_cmd(h, callback, p, session)
        break
      end
      next if flags.include? :invalid_player
      if callback == :do_social
        process_callback(h, callback, p, content)
      elsif flags.include? :override
        process_callback(h, callback, p, qi[:override_response])
      elsif check_disclaimer(p)
        temp = session.temperature
        history = session.get_history(p, callback)
        response = ChatGPT.new(content, history, temp).get_response
        process_callback(h, callback, p, response)
        session.add_to_history(p, [content, response], callback)
      else
        process_disclaimer(h, p, content)
      end
    end
    sleep 1 unless shutdown_event
    h.write(IAC + WONT + GA)
  end
  log("Detected shutdown event. Exiting.", :error)
  h.send('wave')
  h.done
rescue Net::ReadTimeout, Errno::ECONNRESET, TestReconnectSignal => e
  if session.recons_available
    log("Connection interrupted: #{e}. Forcing reconnect.", :warn)
    h.done
    session.log_recon
    h = ConnectTelnet.new
    q = Queues.new(h, social)
    main_loop(h, session, social, q)
  else
    log("Max reconnects reached. Exiting.", :error)
    h.done
    exit
  end
end

##################################################
# RUNTIME

puts "\n"
abort "-=> Couldn't terminate existing process #{pid}".red if process_conflict

begin
  h = ConnectTelnet.new
rescue Net::ReadTimeout
  abort "-=> Timed out after initial connection (check prompt?)".red
end

social = Social.new
session = Sessions.new
q = Queues.new(h, social)
main_loop(h, session, social, q)
