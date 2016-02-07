class HessenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # und\n+Antwort\s+\n+\s+des Ministers für Wirtschaft, Energie, Verkehr und Landesentwicklung\n+
  # und\s+\n\n\nAntwort\s+\n\n\ndes Ministers für Soziales und Integration\n+
  # und\s+\n+Antwort\s+\n+der Ministerin für Bundes- und Europaangelegenheiten und Bevollmächtigten des\s+\n+Landes Hessen beim Bund
  # und\s+\n+Antwort\s+\n+der Ministerin für Bundes- und Europaangelegenheiten und Bevollmächtigten des\s+\n+Landes Hessen beim Bund\s+\n+\s+\n+\s+\n+Im Einvernehmen mit dem Kultusminister,

  ANSWERERS = /und\s+\n+Antwort\s+\n+\s*de[sr]\s+(.+?)\n(?:[\n\s]{3,}|[\n\s]+Vorbemerkung|[\n\s]+Die\s+Kleine\s+Anfrage\s+)/m

  def extract_answerers
    return nil if @contents.blank?
    ministries = []

    m = @contents.match(ANSWERERS)

    if m.nil?
      m = @contents.match(/Antwort\s\n+der Landesregierung\s\n+auf die Große Anfrage/)
      if m.nil?
        return nil
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
               .gsub(/ der Fragesteller:$/, '')
               .gsub(/^Hessischen /, '')

    ministry = 'Chef der Staatskanzlei' if ministry.start_with? 'Chefs der Staatskanzlei'

    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end

  MINOR_ANSWER_TAG = /und\s+Antwort/m
  MAJOR_ANSWER_TAG = /Antwort\s+der\s+Landesregierung/m

  def is_answer?
    return nil if @contents.blank?
    @contents.scan(MINOR_ANSWER_TAG).present? || @contents.scan(MAJOR_ANSWER_TAG).present?
  end
end