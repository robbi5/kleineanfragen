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
      next if m.nil?
      people << m[1].strip.gsub(/\p{Z}+/, ' ')
      parties << m[2].strip.gsub(/\p{Z}+/, ' ')
    end

    { people: people, parties: parties.uniq }
  end
end