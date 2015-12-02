class RheinlandPfalzPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /K\s*l\s*e\s*i\s*n\s*e\s*A\s*n\s*f\s*r\s*a\s*g\s*e\n\nde[rs]\s+Abgeordneten\s+(.+?)\n\nund\s+A\s*n\s*t\s*w\s*o\s*r\s*t/m

  def extract_originators
    return nil if @contents.nil?

    m = @contents.match(ORIGINATORS)
    return nil if m.nil?

    names = m[1].gsub(/\p{Z}/, ' ')
            .gsub("\n", ' ')
            .gsub(/\s+/, ' ')
            .strip
            .gsub(/\p{Other}/, '')

    NamePartyExtractor.new(names).extract
  end
end