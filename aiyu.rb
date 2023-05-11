# frozen_string_literal: true

Dir[File.join(__dir__, 'lib', '*.rb')].sort.each { |file| require file }
require 'optimist'
require 'yaml'

# Load global config
CONFIG          = YAML.load_file(CONFIG_FILE)
AI_NAME         = CONFIG['ai_name']
ADMIN_NAME      = CONFIG['admin_access']
DEFAULT_PROFILE = CONFIG['default_profile']

# CLI args
o = Optimist.options do
  banner "\nSynopsis: ruby aiyu.rb\n\n"
  opt :profile, 'Specify a talker profile',
      default: DEFAULT_PROFILE
end

# Load profile data
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

# Main application flow: listen for events and process queues
class Main
  include Actions
  include Admin
  include Callbacks

  def initialize(session = nil, social = nil)
    puts "\n"
    resolve_process_conflict
    initialize_persistent_components(session, social)
    initialize_transient_components
    configure_player_settings(@conn)
    @shutdown_event = false
    supervisor_loop until @shutdown_event
  end

  def resolve_process_conflict
    return unless SystemOps.process_conflict
    abort "-=> Couldn't terminate existing process #{pid}".red
  end

  def initialize_persistent_components(session, social)
    @social = social.nil? ? Social.new : social
    @session = session.nil? ? Sessions.new : session
  end

  def initialize_transient_components
    @conn = ConnectTelnet.new
    @que = Queues.new(@conn, @social)
  rescue Net::ReadTimeout
    abort '-=> Timed out after initial connection (check prompt?)'.red
  end

  def supervisor_loop
    @conn.suppress_go_ahead
    do_timed_actions
    process_queue
    sleep QUEUE_IDLE unless @shutdown_event
  rescue Net::ReadTimeout, TestReconnectSignal => e
    attempt_reconnection(e)
  rescue Interrupt
    process_shutdown_event
  end

  def do_timed_actions
    log_time
    do_idle_command(@conn)
    clear_log
  end

  def process_queue
    @que.build_queue.each do |task|
      case task[:flag]
      when :shutdown_event then process_shutdown_event
      when :admin_cmd then process_admin_cmd(task)
      when :social then process_social(task)
      when :override then process_override(task)
      when :chat_gpt then process_chat_request(task)
      end
    end
  end

  def process_admin_cmd(task)
    do_admin_cmd(@conn, task, @session)
  end

  def process_social(task)
    do_callback(@conn, task)
  end

  def process_override(task)
    do_callback(@conn, task)
  end

  def process_chat_request(task)
    return unless verify_disclaimer(task)
    hist = @session.get_history(task[:p], task[:callback])
    task[:response] =
      ChatGPT.new(task[:content], hist, @session.temp).chat
    do_callback(@conn, task)
    @session.append(
      task[:p], [task[:content], task[:response]], task[:callback]
    )
  end

  def verify_disclaimer(task)
    return true if YAML.load_file(DISCLAIMER_LOG)[task[:p]]
    disclaim(@conn, task[:p], task[:content])
    return false
  end

  def attempt_reconnection(err)
    process_shutdown_event(:recon) unless @session.recons_available
    log("Connection interrupted: #{err}. Forcing reconnect.", :warn)
    @conn.done
    @session.log_recon
    Main.new(@session, @social)
  end

  def process_shutdown_event(type = nil)
    @shutdown_event = true
    case type
    when :recon
      log('Max reconnects reached. Exiting.', :error)
    else
      log('Detected shutdown event or interrupt. Exiting.', :error)
    end
    @conn.done
    exit
  end
end

##################################################
# RUNTIME

Main.new
