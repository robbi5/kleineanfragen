class SaarlandPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /Anfrage\s+de[rs]\s+Abgeordneten\s+([^\(]+)\s+\(([^\)]+)\)/m
  IS_MAJOR = /W\s?O\s?R\s?T\s+.+?\s+zu\sder\s+[gG]roßen\sAnfrage/m

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

  def extract_doctype
    return nil if @contents.nil?
    if !@contents.scan(IS_MAJOR).blank?
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    else
      Paper::DOCTYPE_WRITTEN_INTERPELLATION
    end
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