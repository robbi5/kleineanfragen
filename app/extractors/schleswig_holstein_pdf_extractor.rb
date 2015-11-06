class SchleswigHolsteinPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ANSWERERS = /und\s+Antwort\s+der\s+Landesregierung\s+-[ ]+([^\n]+)\s+/m

  def extract_answerers
    return nil if @contents.blank?
    ministries = []

    m = @contents.match(ANSWERERS)
    return nil if m.nil?

    # clean and normalize ministry name
    ministry = clean_text(m[1]).gsub(/([Mm])inister(in)?($|\s)/, '\1inister/in\3')
    ministries << ministry unless ministry.blank?

    { ministries: ministries }
  end

  private

  def clean_text(text)
    text.gsub(/\p{Z}/, ' ')
      .gsub("\n", ' ')
      .gsub(/\s+/, ' ')
      .strip
      .gsub(/\p{Other}/, '') # invisible chars & private use unicode
  end
end