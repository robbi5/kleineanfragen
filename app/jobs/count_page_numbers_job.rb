class CountPageNumbersJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    logger.info "Counting Pages of the Paper [#{paper.body.state} #{paper.full_reference}]"

    # FIXME: not multi host capable
    unless File.exist? paper.local_path
      fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found"
    end

    count = Docsplit.extract_length paper.local_path
    paper.page_count = count
    paper.save
  end
end