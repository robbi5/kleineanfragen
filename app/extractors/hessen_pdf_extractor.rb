class HessenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # und\n+Antwort\s+\n+\s+des Ministers für Wirtschaft, Energie, Verkehr und Landesentwicklung\n+
  # und\s+\n\n\nAntwort\s+\n\n\ndes Ministers für Soziales und Integration\n+
  # und\s+\n+Antwort\s+\n+der Ministerin für Bundes- und Europaangelegenheiten und Bevollmächtigten des\s+\n+Landes Hessen beim Bund
  # und\s+\n+Antwort\s+\n+der Ministerin für Bundes- und Europaangelegenheiten und Bevollmächtigten des\s+\n+Landes Hessen beim Bund\s+\n+\s+\n+\s+\n+Im Einvernehmen mit dem Kultusminister,

  ANSWERERS = /und\s+\n+Antwort\s+\n+\s*de[sr]\s+(.+?)\n[\n\s]+(?:Vorbemerkung|Die|Im Einvernehmen)/m

  def extract_answerers
    return nil if @contents.blank?
    ministries = []

    m = @contents.match(ANSWERERS)

    if m.nil?
      m = @contents.match(/Antwort\s\n+der Landesregierung\s\n+auf die Große Anfrage/)
      if m.nil?
        return { ministries: [] }
      else
        return { ministries: ['Landesregierung'] }
      end
    end

    ministry = m[1]
               .gsub(/\p{Z}/, ' ')
               .gsub(/\-\n+/, '')
               .gsub("\n", ' ')
               .gsub(/\s+/, ' ')
               .gsub(/\s+,\s+/, ', ')
               .strip
               .gsub(/\p{Other}/, '') # invisible chars & private use unicode
               .gsub(/inisters\s/, 'inister ')
               .gsub(/inisters$/, 'inister')

    ministry = 'Chef der Staatskanzlei' if ministry == 'Chefs der Staatskanzlein'

    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end
end