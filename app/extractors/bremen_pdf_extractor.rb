class BremenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
    @doctype = paper.doctype
  end

  ORIGINATORS = /\d+.+[\?\.\\](?:\n\n(.+)\s+und\s+Fraktion\s+[^\n]+)+.+(?:Antwort\s+des\s+Senats|Der\s+Senat\s+beantwortet)/m
  # PARTIES = /Kleine\s+Anfrage\s+der\s+Fraktion\s+(?:der)?(.+?)\s+vom?/m

  def extract_originators
    return nil if @contents.nil? || @doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
    people = []
    # parties = []
    return nil if !@contents.include?('und Fraktion')
    m = @contents.match(ORIGINATORS)
    return nil if m.nil?

    m[1].split(',').each do |person|
      person = person.gsub(/\p{Z}/, ' ')
               .gsub("\n", ' ')
               .gsub(/\s+/, ' ')
               .strip
               .gsub(/\p{Other}/, '') # invisible chars & private use unicode
      people << person unless person.blank?
    end

    # p = @contents.match(PARTIES)
    # return {} if p.nil?

    # party = p[1].gsub(/\p{Z}/, ' ')
    #        .gsub(/vom$/, '')
    #        .gsub("\n", ' ')
    #        .gsub(/\s+/, ' ')
    #        .strip
    #        .gsub(/\p{Other}/, '') # invisible chars & private use unicode
    # parties << party unless party.blank?

    { people: people, parties: [] }
  end

  def extract_published_at
    return nil if @contents.nil?

    m = @contents.match(/\s+\d+\.\s+Wahlperiode\s+([\d\.]+)\s+/m)
    return nil if m.nil?

    if m[1].match(/\A\d+\.\d{2}\.\d{2}\z/)
      Date.strptime(m[1], '%d.%m.%y')
    else
      Date.parse m[1]
    end
  end
end