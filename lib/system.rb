# frozen_string_literal: true

# Localhost system operations
module SystemOps
  extend self

  def process_conflict
    pids = conflicting_pids
    return unless pids
    pids.each do |pid|
      puts "-=> Killing existing process #{pid}"
      Process.kill('TERM', pid)
    end
    return conflicting_pids ? conflicting_pids[0] : false
  end

  private

  def conflicting_pids
    matching_pids = `pgrep -f aiyu.rb`.split("\n").map(&:to_i)
    matching_pids.delete(Process.pid)
    return matching_pids
  end
end
