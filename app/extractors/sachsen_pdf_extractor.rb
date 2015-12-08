class SachsenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  # from: https://de.wikipedia.org/wiki/S%C3%A4chsische_Staatsregierung
  MINISTRIES = [
    'Staatskanzlei',
    'Staatsministerium für Wirtschaft, Arbeit und Verkehr',
    'Staatsministerium der Finanzen',
    'Staatsministerium des Innern',
    'Staatsministerium der Justiz',
    'Staatsministerium für Kultus',
    'Staatsministerium für Soziales und Verbraucherschutz',
    'Staatsministerium für Umwelt und Landwirtschaft',
    'Staatsministerium für Wissenschaft und Kunst'
  ]

  THRESHOLD = 0.63

  # Sachsens answers are in a letter like format
  # so in the first few lines there is always some kind of "sender address"
  # we are using that to extract the answering ministry
  def extract_answerers
    return nil if @contents.blank?

    first_block = @contents[0...60]
                  .gsub(/\p{Z}/, ' ')
                  .gsub(/\n/, ' ')
                  .gsub(/\s+/, ' ')
                  .strip
                  .gsub(/\p{Other}/, '') # invisible chars & private use unicode

    # Fix OCR things
    first_block = first_block
                  .gsub(/(\D)?1(\D)?/, "\\1I\\2")
                  .gsub('MINISTEWUM', 'MINISTERIUM')
                  .gsub('MINISTEDIUM', 'MINISTERIUM')
                  .gsub('MINISTETOUM', 'MINISTERIUM')
                  .gsub('MIIMISTERIUM', 'MINISTERIUM')
                  .gsub('MlNlSTERlUM', 'MINISTERIUM')
                  .gsub(/\p{Punctuation}/, '')

    # lowercase it
    first_block = first_block.mb_chars.downcase.to_s

    # remove prefix
    first_block.gsub!(/^s.chsisches?\s+/, '')

    # add missing prefix
    first_block.gsub!(/^des/, 'staatsministerium des')

    # remove things after the name
    m = first_block.match(/(.+?)\s+(?:postfach|freistaat|der\s+staat|s.chsische)/)
    if !m.nil?
      first_block = m[1]
    end

    # and match it against known ministries
    result = FuzzyMatch.new(MINISTRIES).find(first_block, threshold: THRESHOLD)

    ## for debugging: use explain
    # FuzzyMatch.new(MINISTRIES).explain(first_block, threshold: THRESHOLD)

    ministries = []
    ministries << result unless result.nil?

    { ministries: ministries }
  end
end