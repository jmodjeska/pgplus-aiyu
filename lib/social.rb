class Social
  def initialize(profile)
    @profile = profile
    @socials = learn_socials
    @overrides = YAML.load_file('config/overrides.yaml')
  end

  private def learn_socials
    socs = {}
    soc_dir = CONFIG.dig('profiles', @profile, 'socials_dir')
    skipped = []
    begin
      Dir.foreach(soc_dir) do |f|
        next if f == '.' or f == '..'
        next unless File.readlines("#{soc_dir}/#{f}")[2].match('4')
        soc = File.readlines("#{soc_dir}/#{f}")[6]
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
    do_social = {}
    str.match(/^> (.*?) (.*?)$/)
    if ($1 && $2)
      p, used_soc = $1, $2
      @socials.each do |k, v|
        if used_soc.match(v)
          do_social[:p], do_social[:soc] = p, @socials.keys.sample
          break
        end
      end
    end
    return do_social
  end
end
