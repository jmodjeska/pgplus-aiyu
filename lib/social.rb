# frozen_string_literal: true

# Learn and use socials
class Social
  def initialize
    @socials = {}
    @skipped_socials = []
    learn_all_socials
  end

  def respond_to_social(used_soc)
    @socials.each_value do |v|
      next unless used_soc.match(v)
      return @socials.keys.sample
    end
  end

  private

  def learn_all_socials
    Dir.foreach(SOCIALS_DIR) do |f|
      next if ['.', '..'].include?(f)
      next unless File.readlines("#{SOCIALS_DIR}/#{f}")[2].match('4')
      used_msg = File.readlines("#{SOCIALS_DIR}/#{f}")[6]
      learn_social(f, used_msg)
    end
    skipped = "[skipped: #{@skipped.join(', ')}]" if @skipped&.length&.positive?
    puts "-=> Learned #{@socials.length} complex socials #{skipped}"
  rescue StandardError => e
    puts "-=> Error learning socials:\n #{e}"
  end

  # Socials resemble regexes so this mostly works. It skips hard-to-parse
  # messages like, "Someone points and laughs at you :{o|-||O|*|^|@|#})"
  def learn_social(social_name, msg)
    @socials[social_name] = Regexp.new(msg.gsub('{', '(').gsub('}', ')').strip)
  rescue StandardError
    @skipped_socials << "'#{social_name}'"
  end
end
