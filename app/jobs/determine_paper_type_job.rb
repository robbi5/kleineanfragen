class DeterminePaperTypeJob < PaperJob
  queue_as :meta

  EXTRACTORS = {
    'MV' => MvPDFHasAnswerExtractor,
    'HH' => HamburgPDFHasAnswerExtractor
  }

  def perform(paper)
    return unless EXTRACTORS.keys.include?(paper.body.state)
    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?
    paper.is_answer = EXTRACTORS[paper.body.state].new(paper).is_answer?
    paper.save
  end
end