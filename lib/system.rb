# frozen_string_literal: true

# Localhost system operations
module SystemOps
  extend self

  def process_conflict
    pid.nil? ? (return false) : `kill #{pid}`
    puts "-=> Terminating existing aiyu.rb process #{pid}"
    return pid.nil? ? false : pid
  end

  private

  def pid
    cmd = `ps aux | grep aiyu.rb | grep -v grep`
    return unless cmd.match(/^(.*?)(\d+)\s(.*?)aiyu.rb\n$/)
    return if ::Regexp.last_match(2).to_i == Process.pid
    return ::Regexp.last_match(2)
  end
end
