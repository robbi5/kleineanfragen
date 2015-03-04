class HamburgPDFHasAnswerExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ANSWERED_TAG = /und.*antwort.*des.*Senats.*betr\.\:/im

  def is_answer?
    return nil if @contents.nil?
    @contents.scan(ANSWERED_TAG).present?
  end
end