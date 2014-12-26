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
      people << m[1]
      parties << m[2]
    end

    { people: people, parties: parties.uniq }
  end
end