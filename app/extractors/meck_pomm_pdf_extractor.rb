class MeckPommPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # Der Minister für Bildung, Wissenschaft und Kultur hat namens der Landesregierung die Kleine Anfrage mit

  ANSWERERS = /\s*(?:Der|Die)\s+(Minister.+?.*)(?:\shat\s+namens\s+der\s+Landesregierung\s+die)\s+(?:[kK]leine|[gG]roße)?\s*An/m
  ORIGINATORS_PARTY = /KLEINE\s+ANFRAGE\s*de[rs]\s+Abgeordneten\s+.+?,\s+Fraktion\s+(?:d[ei][er])?(.+?)\n/m

  def extract_answerers
    return nil if @contents.nil?
    ministries = []

    m = @contents.match(ANSWERERS)
    return nil if m.nil?

    ministry = m[1].gsub(/Minister(in)*/, 'Ministerium') # normalize to ministerium
    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end

  def extract_originators
    return nil if @contents.nil?
    parties = []

    m = @contents.match(ORIGINATORS_PARTY)
    return nil if m.nil?

    party = m[1].gsub(/\p{Z}/, ' ')
            .gsub("\n", ' ')
            .gsub(/\s+/, ' ')
            .gsub(/\p{Other}/, '')
            .gsub(/\p{Ll}/, '')
            .strip

    parties << party unless party.blank?

    { people: [], parties: parties }
  end
end
