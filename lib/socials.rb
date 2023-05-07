class Socials
  def initialize(profile)
    @profile = profile
    @socials = {}
    learn_socials
  end

  private def learn_socials
    soc_dir = CONFIG.dig('profiles', @profile, 'socials_dir')
    skipped = []
    begin
      Dir.foreach(soc_dir) do |f|
        next if f == '.' or f == '..'
        next unless File.readlines("#{soc_dir}/#{f}")[2].match('4')
        soc = File.readlines("#{soc_dir}/#{f}")[6]
        begin
          @socials[f] = Regexp.new(soc.gsub('{', '(').gsub('}', ')').strip)
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
    puts "-=> Learned #{@socials.length} socials #{skipped}"
    return @socials
  end

  def parse(str)
    do_social = {}
    str.match(/^> (.*?) (.*?)$/)
    ($1 && $2) ? (p, used_soc = $1, $2) : (return do_social)
    @socials.each do |k, v|
      if used_soc.match(v)
        do_social[:p], do_social[:soc] = p, k
        break
      end
    end
    return do_social
  end
end