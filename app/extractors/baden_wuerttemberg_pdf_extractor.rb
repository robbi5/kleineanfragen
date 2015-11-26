class BadenWuerttembergPDFExtractor
  def initialize(paper)
    @contents = paper.contents
    @doctype = paper.doctype
  end

  ORIGINATORS_MINOR = /Kleine\s+Anfrage\s+de(?:r|s)\s+Abg.\s+(.+?)\s+und\s+Antwort/m
  ORIGINATORS_MAJOR = /Große\s+Anfrage\s+der\s+Fraktion\s+der\s+(.+?)\s+/m

  def extract_originators
    return nil if @contents.nil?
    case @doctype
    when Paper::DOCTYPE_MAJOR_INTERPELLATION
      extract_originators_major
    when Paper::DOCTYPE_MINOR_INTERPELLATION
      extract_originators_minor
    end
  end

  def extract_originators_minor
    return nil if @contents.include?('und Fraktion')
    m = @contents.match(ORIGINATORS_MINOR)
    return nil if m.nil?

    names = m[1].gsub(/de(?:r|s)\s+Abg.\s+/, '')
    NamePartyExtractor.new(names, NamePartyExtractor::NAME_PARTY_COMMA).extract
  end

  def extract_originators_major
    return nil if !@contents.include?('Fraktion')
    m = @contents.match(ORIGINATORS_MAJOR)
    return nil if m.nil?

    party = m[1].strip
    { parties: [party], people: [] }
  end

  ANSWERERS = /und\s+Antwort\s+des\s+((Staats)*[mM]inisteriums.*)(?:\s+\n)/m
  RELATED_MINISTRY = /(?:im\s+Einvernehmen\s+mit\s+dem\s+)(Ministerium.*)(?:\s+die\s+(?:[kK]leine|[gG]roße)?\s*An)/m

  def extract_answerers
    return nil if @contents.blank?
    ministries = []

    m = @contents.match(ANSWERERS)
    return nil if m.nil?

    # clean and normalize ministry name
    ministry = normalize_ministry(m[1])
    ministries << ministry unless ministry.blank?

    related_ministry_match = @contents.match(RELATED_MINISTRY)
    unless related_ministry_match.nil?
      related_ministry = normalize_ministry(related_ministry_match[1])
      ministries << related_ministry unless related_ministry.blank?
    end

    { ministries: ministries }
  end

  def normalize_ministry(ministry)
    ministry
      .gsub("\n", ' ')
      .gsub(/Ministeriums/, 'Ministerium')
      .gsub(/ministeriums/, 'ministerium')
  end
end