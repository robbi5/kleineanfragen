class BayernPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []
    [
      /Abgeordneten ([\D\n]+?)\s(\p{Lu}[\p{Lu} \d\/\n]+)\b/m,
      /Abgeordneten ([\D\n]+?)\s(\p{Lu}[\p{Lu} \d\/]+)\b/m,
      /Abgeordneten ([\D\n]+?)\p{Zs}(\p{Lu}[\p{Lu} \d\/]+)\b/m,
      /Abgeordneten ([\D\n]+?)\n(\p{Lu}[\p{Ll}\p{Lu} \d\/]+)\b/m,
      # /Abgeordneten ([\D\n]+?)\s([[:upper:] \d\/]+)/m
    ].each do |regex|
      m = @contents.match(regex)
      next unless m

      person = m[1].gsub(/\p{Z}/, ' ').gsub("\n", ' ').gsub(' und', ', ')
      if person.include?(',')
        people.concat person.split(',').map { |s| s.gsub(/\p{Z}+/, ' ').strip }
      else
        people << person.gsub(/\p{Z}+/, ' ').strip
      end
      parties << m[2].gsub(/[\n\p{Z}]+/, ' ').strip

      # only one regex must match
      break
    end
    { people: people, parties: parties }
  end

  def extract_answerers
    return nil if @contents.nil?
    ministries = []

    # Antwort\nder Staatsministerin für Gesundheit und Pflege\nvom 20.08.2014
    p = @contents.match(/Antwort\n[dD]e[rs]\s+Staatsminister(?:s|in)?\s+(für\s+[\p{L}\s\,]+)\s+vom/m)
    if p
      ministries << "Staatsministerium #{p[1].strip}"
    end

    # Antwort\nDer Leiterin der Bayerischen Staatskanzlei\nStaatsministerin für Bundesangelegenheiten und Son-deraufgaben
    # Antwort\ndes Leiters der Bayerischen Staatskanzlei und\nStaatsministers für Bundesangelegenheiten und Son-deraufgaben
    # Antwort\nder Leiterin der Bayerischen Staatskanzlei Staatsministerin\n für Bundesangelegenheiten und Sonderaufgaben")
    p = @contents.match(/Antwort\n[dD]e[rs]\s+(?:Leiters|Leiterin)\s+der\s+([\p{L}\s\,]+)\s+vom/m)
    if p
      line = p[1].strip.split("\n").first.strip
      line.gsub!(/(.+)\s+(?:und|Staatsministeri?n?)/, '\1')
      ministries << 'Bayerische Staatskanzlei' if line == 'Bayerischen Staatskanzlei'
    end

    # Antwort\nder Bayerischen Staatskanzlei\nvom
    if @contents.match(/Antwort\nder (Bayerischen\s+Staatskanzlei)\s+vom/m)
      ministries << 'Bayerische Staatskanzlei'
    end

    # Antwort\ndes Staatsministeriums des Innern, für Bau und Verkehr\nvom 10.10.2014
    m = @contents.match(/Antwort\nd[ea]s (Staatsministeriums?\s[\p{L}\s\,\-\u00AD]+)\s+vom/m)
    if m
      ministry = m[1].gsub(/\u00AD/, '').gsub(/(\p{L}+)\-\p{Zs}*\n(\p{L}+)/m, '\1\2').gsub(/\n/, '').strip
      ministry.gsub!(/^Staatsministeriums/, 'Staatsministerium') # remove Genitiv
      ministries << ministry
    end

    { ministries: ministries }
  end
end