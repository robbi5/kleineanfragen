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
      people << m[1].gsub(/\p{Z}+/, ' ').strip
      parties << m[2].gsub(/\p{Z}+/, ' ').strip.sub(/^Fraktion\s+/, '') unless m[2].nil?
    end

    { people: people, parties: parties.uniq }
  end
end