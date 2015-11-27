class BrandenburgPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # Namens der Landesregierung beantwortet die Ministerin für Wissenschaft, Forschung und Kultur die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet die Ministerin für Arbeit, Soziales, Ge-\nsundheit, Frauen und Familie die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet die Ministerin für Wissenschaft, For-\nschung und Kultur die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet der Minister des Innern und für Kommunales die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet der Minister des Innern und für Kommunales die KleineAnfrage wie folgt:
  # Namens der Landesregierung beantwortet der Minister der Finanzen die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet der Chef der Staatskanzlei die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet das Ministerium der Finanzen die Kleine Anfrage wie folgt:
  # Namens der Landesregierung beantwortet der Minister der Finanzen die Anfrage wie folgt:
  # Im Namen der Landesregierung beantwortet der Minister für Wirtschaft und Energie die Kleine Anfrage wie folgt:
  # Namens der Landregierung beantwortet der Minister der Justiz und für Europa und Verbraucherschutz die Kleine Anfrage wie folgt:

  ANSWERERS = /Namens?\s+der\s+Land(?:es)?regierung\s+beantwortet\s+(?:der|die|das)\s+((?:Minister|Chef).+?)\s+die\s*(?:[kK]leine|[gG]roße)?\s*An/m

  def extract_answerers
    return nil if @contents.nil?
    ministries = []

    m = @contents.match(ANSWERERS)
    return nil if m.nil?

    ministry = m[1]
               .gsub(/\p{Z}/, ' ')
               .gsub(/\-\n+/, '')
               .gsub("\n", ' ')
               .gsub(/\s+/, ' ')
               .gsub(/\s+,\s+/, ', ')
               .strip
               .gsub(/\p{Other}/, '') # invisible chars & private use unicode
               .gsub(/,$/, '')
               .gsub(/\s+des\s+Landes\s+Brandenburg$/, '') # unnecessary suffix
               .gsub(/^Minister(?:in)?\s/, 'Ministerium ') # normalize ministry

    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end
end