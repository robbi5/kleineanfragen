class SaarlandPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /Anfrage\s+de[rs]\s+Abgeordneten.*\n/m

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []
    @contents.scan(ORIGINATORS).each do |m|
      party = m.scan(/\(.+\)/)[0].gsub(/[()]/, '')
      parties << party
      person = m.gsub(/\p{Z}/, ' ')
        .gsub("\n", ' ')
        .gsub(/\s+/, ' ')
        .gsub(/\(.*\)/, '') # remove party
        .strip
        .gsub(/\p{Other}/, '') # invisible chars & private use unicode
        .sub(/^Anfrage\s/, '')
        .sub(/^de[rs]\s/, '')
        .sub(/Abgeordneten\s+/, '')
      people << person unless person.blank?
    end

    { people: people, parties: parties }
  end
end