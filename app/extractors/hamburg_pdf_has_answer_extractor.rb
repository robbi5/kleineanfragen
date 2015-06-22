class HamburgPDFHasAnswerExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ANSWERED_TAG = /und\s+Antwort\s+des\s+Senats\s+Betr\.\:/i

  def is_answer?
    return nil if @contents.nil?
    @contents.scan(ANSWERED_TAG).present?
  end
end