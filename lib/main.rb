# frozen_string_literal: true

# Main application flow: listen for events and process queues
class Main
  include Actions
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
    abort "-=> #{ERR_TERMINATE_FAIL} #{pid}".red
  end

  def initialize_persistent_components(session, social)
    @social = social.nil? ? Social.new : social
    @session = session.nil? ? Sessions.new : session
  end

  def initialize_transient_components
    @conn = ConnectTelnet.new
    @que = Queues.new(@conn, @social)
  rescue Net::ReadTimeout
    abort "-=> #{ERR_CONN_TIMED_OUT}".red
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
    harass_idle_person(@conn)
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
    ac = Admin.new(@conn, task, @session)
    ac.do_admin_cmd
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
    task[:response] = ChatGPT.new(task[:content], hist, @session.temp).chat
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
    log("#{ERR_CONN_INTERRUPT} #{err}", :warn)
    @conn.done
    @session.log_recon
    Main.new(@session, @social)
  end

  def process_shutdown_event(type = nil)
    @shutdown_event = true
    shutdown_message = type == :recon ? SHUTDOWN_MAX_RECON : SHUTDOWN_GENERAL
    log(shutdown_message, :error)
    @conn.done
    exit
  end
end
