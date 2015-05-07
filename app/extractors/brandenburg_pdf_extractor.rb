class BrandenburgPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # Namens der Landesregierung beantwortet die Ministerin für Wissenschaft, Forschung und Kultur die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet die Ministerin für Arbeit, Soziales, Ge-\nsundheit, Frauen und Familie die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet die Ministerin für Wissenschaft, For-\nschung und Kultur die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet der Minister des Innern und für Kommunales die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet der Minister der Finanzen die Kleine Anfrage wie folgt:

  ANSWERERS = /Namens\s+der\s+Landesregierung\s+beantwortet\s+(?:der|die)\s+(Minister.+?)\s+die\s+(?:Kleine|Große)\s+An/m

  def extract_answerers
    return nil if @contents.nil?
    ministries = []

    m = @contents.match(ANSWERERS)

    return { ministries: [] } if m.nil?

    ministry = m[1]
               .gsub(/\p{Z}/, ' ')
               .gsub(/\-\n+/, '')
               .gsub("\n", ' ')
               .gsub(/\s+/, ' ')
               .gsub(/\s+,\s+/, ', ')
               .strip
               .gsub(/\p{Other}/, '') # invisible chars & private use unicode
               .gsub(/,$/, '')

    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end
end