class ExtractTextFromPaperJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    Rails.logger.info "Extracting Text of the Paper [#{paper.body.state} #{paper.full_reference}]"

    # FIXME: not multi host capable
    fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found" unless File.exist?(paper.local_path)

    text = paper.extract_text
    if text.blank?
      Rails.logger.warn "Can't extract text from Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    paper.contents = text
    paper.save

    ExtractPeopleNamesJob.perform_later(paper)
  end
end