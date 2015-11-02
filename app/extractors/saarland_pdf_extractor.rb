class SaarlandPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /Anfrage\s+de[rs]\s+Abgeordneten\s+([^\(]+)\s+\(([^\)]+)\)/m

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []
    m = @contents.match(ORIGINATORS)
    return nil if m.nil?

    party = clean_text(m[2])
    parties << party

    names = clean_text(m[1])
    names.gsub(' und ', ',').split(',').each do |person|
      p = person.strip
      people << p unless p.blank?
    end

    { people: people, parties: parties }
  end

  private

  def clean_text(text)
    text.gsub(/\p{Z}/, ' ')
      .gsub("\n", ' ')
      .gsub(/\s+/, ' ')
      .strip
      .gsub(/\p{Other}/, '') # invisible chars & private use unicode
  end
end