class ThueringenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /A\s+n\s+f\s+r\s+a\s+g\s+e\s+de[rs]\s+Abgeordneten\s+([^\(]+)\s+\(([^\)]+)\)/m

  def extract_originators
    return nil if @contents.nil?

    m = @contents.match(ORIGINATORS)
    return nil if m.nil?

    parties = []
    parties << clean_text(m[2])

    ## not using person, because its only the last name.
    # people = []
    # person = clean_text(m[1])
    # people << person unless person.blank?

    { people: [], parties: parties }
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