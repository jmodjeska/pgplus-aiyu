module SystemOps
  private def get_pid
    cmd = `ps aux | grep aiyu.rb | grep -v grep`
    if cmd.match(/^(.*?)(\d+)\s(.*?)aiyu.rb\n$/)
      return $2 unless $2.to_i == $$
    end
  end

  def process_conflict
    pid = get_pid
    get_pid.nil? ? (return false) : (`kill #{pid}`)
    puts "-=> Terminating existing aiyu.rb process #{pid}"
    return (get_pid.nil?) ? false : pid
  end
end
