class NordrheinWestfalenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /Antwort\s+der\s+Landesregierung\s+auf\s+die\s+[kK]leine\s+Anfrage.+?de[rs]\s+Abgeordneten\s+(.+?)\s+(\p{Lu}+?)\s+Drucksache/m

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []

    @contents.scan(ORIGINATORS).each do |m|
      m[0].gsub(' und ', ',').split(',').each do |person|
        person = person.gsub(/\p{Z}/, ' ')
                 .gsub("\n", ' ')
                 .gsub(/\s+/, ' ')
                 .strip
                 .gsub(/\p{Other}/, '') # invisible chars & private use unicode
        people << person unless person.blank?
      end

      party = m[1].gsub("\n", ' ')
              .strip
              .gsub(/\p{Other}/, '')
      parties << party
    end


    { people: people, parties: parties }
  end
end