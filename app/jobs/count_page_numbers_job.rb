class CountPageNumbersJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    Rails.logger.info "Counting Pages of the Paper [#{paper.body.state} #{paper.full_reference}]"

    # FIXME: not multi host capable
    unless File.exist? paper.local_path
      fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found"
    end

    count = paper.extract_page_count
    paper.page_count = count
    paper.save
  end
end