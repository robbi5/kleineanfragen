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

      person = m[1].gsub(/\p{Z}+/, ' ').gsub("\n", ' ').gsub(' und', ', ').gsub(/(\S+)\s-(\S+)/, '\1-\2')
      if person.include?(',')
        people.concat person.split(',').map(&:strip)
      else
        people << person.strip
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
    # Antwort\nStaatsministerin für Gesundheit und Pflege\nvom 21.04.2015
    p = @contents.match(/Antwort\n(?:[dD]e[rs]\s+)?Staatsminister(?:s|in)?\s+(für\s+[\p{L}\s\,]+)\s+vom/m)
    if p
      ministry = p[1].gsub(/\n/, ' ').gsub(/\s+/, ' ').strip
      ministries << "Staatsministerium #{ministry}"
    end

    # Antwort\nDer Leiterin der Bayerischen Staatskanzlei\nStaatsministerin für Bundesangelegenheiten und Son-deraufgaben
    # Antwort\ndes Leiters der Bayerischen Staatskanzlei und\nStaatsministers für Bundesangelegenheiten und Son-deraufgaben
    # Antwort\nder Leiterin der Bayerischen Staatskanzlei Staatsministerin\n für Bundesangelegenheiten und Sonderaufgaben")
    # Antwort\ndie Leiterin der Staatskanzlei\nStaatsministerin für Bundesangelegenheiten
    p = @contents.match(/Antwort\n\s*[dD]i?e[rs]?\s+(?:Leiters|Leiterin)\s+der\s+([\p{L}\s\,]+)\s+vom/m)
    if p
      stknzl = ['Bayerischen Staatskanzlei', 'Staatskanzlei']
      line = p[1].strip.split("\n").first.strip
      line = line.gsub(/(.+?)(?:\s+und.*|\s+Staatsministeri?n?.*|,.*)?$/, '\1')
      ministries << 'Bayerische Staatskanzlei' if stknzl.include? line
    end

    # Antwort\nder Bayerischen Staatskanzlei\nvom
    if @contents.match(/Antwort\nder (Bayerischen\s+Staatskanzlei)\s+vom/m)
      ministries << 'Bayerische Staatskanzlei'
    end

    # Antwort\ndes Staatsministeriums des Innern, für Bau und Verkehr\nvom 10.10.2014
    m = @contents.match(/Antwort\s+d[ea]s (St?aatsministeriums?\s[\p{L}\s\,\-\u00AD]+)\s+(?:vom|vom\s+\d+|\d+)/m)
    if m
      ministry = m[1]
                 .gsub(/\u00AD/, '')
                 .gsub(/(\p{L}+)\-\p{Zs}*\n(\p{L}+)/m, '\1\2')
                 .gsub(/\n/, ' ')
                 .gsub(/\s+/, ' ')
                 .gsub(/Staatsministeriums?\s+(Staatsministerium.+)/, '\1') # dup
                 .gsub(/\s+vom\z/, '')
                 .strip
      ministry.gsub!(/^St?aatsministeriums/, 'Staatsministerium') # remove typo, Genitiv
      ministries << ministry
    end

    { ministries: ministries }
  end
end