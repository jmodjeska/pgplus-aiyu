Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
require 'optimist'
require 'yaml'
include Actions
include Admin

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

def main_loop(h, session, profile, social, q)
  shutdown_event = false
  sleep CONFIG.dig('timings', 'slowness_tolerance')
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
        admin_do_cmd(h, callback, p)
        break
      end
      next if flags.include? :invalid_player
      if callback == :do_social
        process_callback(h, callback, p, content)
      elsif flags.include? :override
        process_callback(h, callback, p, qi[:override_response])
      elsif check_disclaimer(p)
        history = session.get_history(p, callback)
        response = ChatGPT.new(content, history).get_response
        process_callback(h, callback, p, response)
        session.add_to_history(p, [content, response], callback)
      else
        process_disclaimer(h, p, content)
      end
    end
    sleep 1 unless shutdown_event
  end
  log("Detected shutdown event. Exiting.", :error)
  h.send('wave')
  h.done
rescue Net::ReadTimeout, Errno::ECONNRESET, TestReconnectSignal => e
  if session.recons_available
    log("Connection interrupted: #{e}. Forcing reconnect.", :warn)
    h.done
    session.log_recon
    h = ConnectTelnet.new(profile)
    q = Queues.new(h, profile, social)
    main_loop(h, session, profile, social, q)
  else
    log("Max reconnects reached. Exiting.", :error)
    h.done
    exit
  end
end

##################################################
# RUNTIME

begin
  h = ConnectTelnet.new(profile)
rescue Net::ReadTimeout
  abort "-=> Timed out after initial connection (check prompt?)".red
end

social = Social.new(profile)
session = Sessions.new
q = Queues.new(h, profile, social)
main_loop(h, session, profile, social, q)
