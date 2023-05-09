class Social
  def initialize
    @socials = learn_socials
    @overrides = YAML.load_file('config/overrides.yaml')
  end

  private def learn_socials
    socs = {}
    skipped = []
    begin
      Dir.foreach(SOCIALS_DIR) do |f|
        next if f == '.' or f == '..'
        next unless File.readlines("#{SOCIALS_DIR}/#{f}")[2].match('4')
        soc = File.readlines("#{SOCIALS_DIR}/#{f}")[6]
        begin
          socs[f] = Regexp.new(soc.gsub('{', '(').gsub('}', ')').strip)
        rescue
          skipped << "'#{f}'"
          next
        end
      end
    rescue StandardError => e
      puts "-=> Error learning socials:\n #{e}"
      return nil
    end
    skipped = (skipped.length > 0) ? "[skipped: #{skipped.join(', ')}]" : ''
    puts "-=> Learned #{socs.length} complex socials #{skipped}"
    return socs
  end

  def get_override(str)
    return false if str.nil?
    @overrides.keys.each do |k|
      if str.match?(/#{k}/i)
        return @overrides[k]
      end
    end
    return false
  end

  def parse(str)
    str.match(/^> (.*?) (.*?)$/)
    return {} unless $1 && $2
    p, used_soc = $1, $2
    do_social = {}
    @socials.each do |k, v|
      if used_soc.match(v)
        do_social[:p], do_social[:soc] = p, @socials.keys.sample
        break
      end
    end
    return do_social
  end
end
