class ExtractTextFromPaperJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    Rails.logger.info "Extracting Text of the Paper [#{paper.body.state} #{paper.full_reference}]"

    # FIXME: not multi host capable
    unless File.exist? paper.local_path
      fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found"
    end

    text = paper.extract_text
    paper.contents = text
    paper.save
  end
end