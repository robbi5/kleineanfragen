class ContainsTableJob < PaperJob
  queue_as :meta

  def perform(paper)
    logger.info "Looking for Tables in Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    options = {}
    options[:skip] = [:looks_like_table_values] if paper.body.state == 'SN'

    result = TableRecognizer.new(paper.contents, options).recognize

    reason = result[:groups].map(&:to_s).join(',')

    logger.info "Probability of Table(s) in Paper [#{paper.body.state} #{paper.full_reference}]: #{result[:probability]} (#{reason})"

    paper.contains_table = result[:probability] >= 1
    paper.save
  end
end