class MvPDFHasAnswerExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  DUE_DATE_TAG = /\(Termin zur Beantwortung.*gemäß.*\)/m

  def is_answer?
    return nil if @contents.nil?
    @contents.scan(DUE_DATE_TAG).blank?
  end
end