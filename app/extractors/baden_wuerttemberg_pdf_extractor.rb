class BadenWuerttembergPDFExtractor
  def initialize(paper)
    @contents = paper.contents
    @doctype = paper.doctype
    @title = paper.title
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

  ANSWERERS = /und\s+Antwort\s+des\s+((?:Staats)?[mM]inisteriums.*?)(?:\s+\n)/m
  RELATED_MINISTRY = /im\s+Einvernehmen\s+mit\s+dem\s+(Ministerium.+?)\s+(?:für\s+die\s+Landesregierung\s+)?die\s+(?:[kK]leine|[gG]roße)?\s*An/m
  MULTIPLE_RELATED_MINISTRIES = /(Ministerium.+?)(?:(?:,|sowie|und\s+mit|und)\s+dem\s+(Ministerium.+))+$/m

  def extract_answerers
    return nil if @contents.blank?

    m = @contents.match(ORIGINATORS_MAJOR)
    return { ministries: ['Landesregierung'] } unless m.nil?

    ministries = []

    m = @contents.match(ANSWERERS)
    return nil if m.nil?

    # clean and normalize ministry name
    ministry = normalize_ministry(m[1])

    add_to(ministries, ministry)

    related_ministry_match = @contents.match(RELATED_MINISTRY)
    unless related_ministry_match.nil?
      add_to(ministries, related_ministry_match[1])
    end

    { ministries: ministries }
  end

  def add_to(ministries, ministry)
    # multiple ministries
    multiple_related = ministry.match(MULTIPLE_RELATED_MINISTRIES)
    if multiple_related
      multiple_related.captures.each do |related_ministry|
        next if related_ministry.blank?
        add_to(ministries, related_ministry)
      end
      return
    end

    ministry = normalize_ministry(ministry)
    ministries << ministry unless ministry.blank?
  end

  def normalize_ministry(ministry)
    # regex matches too much, but the next line is the papers title... so cut it and everything after
    # use just part of the title to prevent new line issues
    shortened_title = @title[0..30]
    unless ministry.index(shortened_title).nil?
      ministry = ministry[0, ministry.index(shortened_title)].strip
    end

    ministry
      .gsub("\n", ' ')
      .gsub(/\s+/, ' ')
      .gsub(/inisteriums/, 'inisterium')
      .strip
  end
end