require 'timeout'

class ContainsClassifiedInformationJob < PaperJob
  queue_as :meta

  def perform(paper)
    logger.info "Looking for classified marked Answers in Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    options = {}
    result = ClassifiedRecognizer.new(paper.contents, options).recognize

    reason = result[:groups].map(&:to_s).join(',')

    logger.info "Probability of classified information in Paper [#{paper.body.state} #{paper.full_reference}]: #{result[:probability]} (#{reason})"

    paper.contains_classified_information = result[:probability] >= 1
    paper.save
  end
end