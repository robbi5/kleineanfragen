class NamePartyExtractor
  def initialize(text)
    @text = text
  end

  def extract
    people = []
    parties = []
    pairs = @text.gsub("\n", '').gsub(' und', ', ').split(',').map(&:strip)

    pairs.each do |line|
      m = line.match(/(.+)\s\((.+)\)/)
      m = ['', line.strip] if m.nil?
      person = m[1].gsub(/\p{Z}+/, ' ').strip
      people << person unless person.blank?
      parties << m[2].gsub(/\p{Z}+/, ' ').strip.sub(/^Fraktion\s+/, '') unless m[2].nil?
    end

    { people: people, parties: parties.uniq }
  end
end