class ExtractRelatedPapersJob < PaperJob
  queue_as :meta

  DIFFERENT_NUMBER_STATES = ['NW', 'RP', 'BB']

  def perform(paper)
    logger.info "Extracting related Papers from Paper [#{paper.body.state} #{paper.full_reference}]"

    count = 0

    if !paper.contents.blank?
      logger.warn "No Text for Paper [#{paper.body.state} #{paper.full_reference}]"
      references = self.class.extract_contents(paper.contents)
      count += add(paper, references, PaperRelation::REASON_REFERENCE_IN_TEXT)
    end

    references = self.class.extract_title(paper.title)
    count += add(paper, references, PaperRelation::REASON_REFERENCE_IN_TITLE)

    logger.info "#{count} references on other papers found in Paper [#{paper.body.state} #{paper.full_reference}]"
  end

  def add(paper, references, reason)
    other_papers = []

    references.each do |full_reference|
      legislative_term, reference = full_reference.split('/')

      # use legislative term of current paper if it is unknown
      # but not if its NW/RP, they have different numbers for interpellations and the papers
      if reference.blank? && !legislative_term.blank? && DIFFERENT_NUMBER_STATES.include?(paper.body.state)
        reference = legislative_term
        legislative_term = paper.legislative_term
      end

      p = Paper.where(body: paper.body, legislative_term: legislative_term, reference: reference).first
      other_papers << p unless p.nil?
    end

    other_papers.each do |other_paper|
      PaperRelation.find_or_create_by(paper: paper, other_paper: other_paper, reason: reason)
    end

    other_papers.size
  end

  def self.extract_title(title)
    references = []

    references.concat title.scan(/Nachfrage zur Schriftlichen Anfrage (\d+\/[\d]+)/).map(&:first)

    references.uniq
  end

  def self.extract_contents(contents)
    references = []
    # NRW uses different numbers for the interpellation and the paper reference
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage \d+ \((?:Drucksachen?|LT-Drs.) (\d+\/[\d\s]+)(?:(?:\sund|,)\s(\d+\/[\d\s]+))*\)/).flatten
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage(?:\/Drucksache)? (?:\([^\)]+?\)\s+)?(\d*\/?[\d\s]+)/).map(&:first) if references.blank?

    # Note: \p{Initial/Final_Punctuation} is not working for „“
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage\:? (?:["'„][^"'“]+?["'“]\s+|zur schriftlichen Beantwortung\s+)?(?:vom \d+\..+?\d+?\s+)?\((?:Drucksache|Drs\.:?|DS|LT-DRS) (\d*\/?[\d\s]+)\)/).map(&:first)
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage vom \d+\..+?\d+,? \(?(?:Drucksache|Drs\.:?|DS|LT-DRS) (\d*\/?[\d\s]+)\)?/).map(&:first)
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage de[rs] Abgeordneten? .+? Drucksache (\d*\/?[\d\s]+)/).map(&:first)
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage mit der Drucksachen-\s*Nr.?:\s*(\d*\/?[\d\s]+)/).map(&:first)
    references.concat contents.scan(/[Ii]n der [Kk]leinen Anfrage(?:\s*,? ?Drs\.?:?|\s+Drs.-?Nr.:?|\s+Nr.|\s+Drucksache)\s+(\d*\/?[\d\s]+)/).map(&:first)
    references.concat contents.scan(/bezieht sich auf Drucksache\s+(\d*\/?[\d\s]+)/).map(&:first)

    references.concat contents.scan(/in Drucksache\s+(\d*\/?[\d\s]+)/).map(&:first)

    references.concat contents.scan(/[Ii]n der [Gg]roßen Anfrage \d+ der Fraktion.*? Drucksache (\d*\/?[\d\s]+)/).map(&:first)

    # remove whitespace
    references = references.reject(&:nil?).map do |ref|
      ref.strip.gsub(/\s+/, '')
    end

    references.uniq
  end
end