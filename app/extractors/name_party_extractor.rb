class NamePartyExtractor
  NAME_BRACKET_PARTY = :nbp
  NAME_PARTY_COMMA = :npc
  REVERSED_NAME_PARTY = :rnp
  FACTION = :faction

  def initialize(text, format = NAME_BRACKET_PARTY)
    @text = text
    @format = format
  end

  def extract
    case @format
    when NAME_BRACKET_PARTY then extract_nbp
    when NAME_PARTY_COMMA then extract_npc
    when REVERSED_NAME_PARTY then extract_rnp
    when FACTION then extract_faction
    else fail 'Unknown format'
    end
  end

  def extract_rnp
    people = []
    parties = []

    @text.split(';').map do |s|
      sa = s.strip.split(',').map(&:strip)
      unless sa.size == 2 # party missing
        party = sa.pop
        parties << self.class.clean_party(party)
      end
      next if sa.blank?
      if sa.last.include?(' ')
        # Space seperated party
        last = sa.pop
        parts = last.split(' ').reject { |p| p.include? 'u.a.' }
        parties << parts.pop if parts.size > 1 && self.class.looks_like_party?(parts.last)
        sa << parts.join(' ')
      end
      if sa.first.include?('Dr.')
        parts = sa.shift.split(' ')
        titles = []
        parts.each do |part|
          if part.include?('.')
            # use seperate array to keep the order
            titles.push part.strip
          else
            sa.unshift part.strip
          end
        end
        sa << titles
      end
      sa.reject!(&:blank?)
      sa.map! do |part|
        if part.include? '('
          part.gsub!(/(.+)\([^\)]+\)/, '\1')
        end
        part
      end
      people << sa.reverse.join(' ') unless sa.size == 0
    end

    { people: people, parties: parties.uniq }
  end

  def extract_npc
    people = []
    parties = []
    pairs = @text.gsub("\n", ' ').gsub(' und', ', ').split(',').map(&:strip)

    pairs.each do |line|
      m = line.match(/\A(.+?)(?:\s([A-Z][a-zA-Z]{2}|[A-Z]{2,}[[:alnum:]\s\/]+))?\z/)
      next if m.nil?
      person = m[1].gsub(/\p{Z}+/, ' ').strip
      people << person unless person.blank?
      parties << m[2].gsub(/\p{Z}+/, ' ').strip unless m[2].nil?
    end

    { people: people, parties: parties.uniq }
  end

  def extract_nbp
    people = []
    parties = []
    pairs = @text.gsub("\n", '').gsub(' und', ', ').split(',').map(&:strip)

    pairs.each do |line|
      m = line.match(/(.+)\s\((.+)\)/)
      m = ['', line.strip] if m.nil?
      person = m[1].gsub(/\p{Z}+/, ' ').strip
      people << person unless person.blank? || person.match(/^\(.+\)$/)
      parties << self.class.clean_party(m[2]) unless m[2].nil?
    end

    { people: people, parties: parties.uniq }
  end

  # e.g. "Fraktion der SPD, Fraktion der CDU und Fraktion DIE LINKE"
  def extract_faction
    parties = []
    @text.split(/,| und /).each do |splitted|
      parties << self.class.clean_party(splitted.strip)
    end
    { people: [], parties: parties }
  end

  def self.looks_like_party?(text)
    !text.match(/\A([A-Z][a-zA-Z]{2}|\p{Lu}{2,}[[:alnum:]\s\/]+)\z/).nil? || text.downcase.strip == 'fraktionslos'
  end

  def self.clean_party(name)
    name.gsub(/\p{Z}+/, ' ').strip.sub(/Fraktion\s+(?:der\s+)?/, '')
  end
end