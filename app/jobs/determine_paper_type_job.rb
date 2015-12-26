class DeterminePaperTypeJob < PaperJob
  queue_as :meta

  EXTRACTORS = {
    'MV' => MvPDFHasAnswerExtractor,
    'HH' => HamburgPDFHasAnswerExtractor,
    'HE' => HessenPDFExtractor,
    'SL' => SaarlandPDFExtractor
  }

  def perform(paper)
    return unless EXTRACTORS.keys.include?(paper.body.state)
    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank? && paper.body.state != 'HE'
    ex = EXTRACTORS[paper.body.state].new(paper)

    paper.is_answer = ex.is_answer? if ex.respond_to? :is_answer?

    if ex.respond_to? :extract_doctype
      type = ex.extract_doctype
      paper.doctype = type unless type.nil?
    end

    paper.save
  end
end