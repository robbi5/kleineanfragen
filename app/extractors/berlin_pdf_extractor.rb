class BerlinPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # \n.................................\nSenatsverwaltung für Stadtentwicklung und Umwelt\n
  # \n_____________________________\nSenatsverwaltung für Gesundheit und Soziales\n
  ANSWERERS = /\n[\.\_]{28,40}\s+(Senatsverwaltung\s+.+)\s\s+\(/m

  def extract_answerers
    return nil if @contents.blank?
    ministries = []

    m = @contents.match(ANSWERERS)
    return nil if m.nil?

    ministry = m[1]
               .gsub(/\p{Z}/, ' ')
               .gsub(/\-\n+/, '')
               .gsub(/\n/, ' ')
               .gsub(/\s+/, ' ')
               .gsub(/\s+,\s+/, ', ')
               .strip
               .gsub(/\p{Other}/, '') # invisible chars & private use unicode

    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end
end