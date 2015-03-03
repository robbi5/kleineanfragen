class ExtractLastModifiedFromPaperJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    logger.info "Extracting Last-Modified from Paper [#{paper.body.state} #{paper.full_reference}]"

    if !Rails.configuration.x.tika_server.blank?
      last_modified = extract_tika(paper)
    else
      last_modified = extract_local(paper)
    end

    fail "Can't extract text from Paper [#{paper.body.state} #{paper.full_reference}]" if last_modified.blank?

    paper.pdf_last_modified = DateTime.parse(last_modified)
    paper.save
  end

  def extract_local(paper)
    # FIXME: not multi host capable
    fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found" unless File.exist?(paper.local_path)

    Docsplit.extract_date(paper.local_path)
  end

  def tika_endpoint
    Addressable::URI.parse(Rails.configuration.x.tika_server).join('./meta').normalize.to_s
  end

  def extract_tika(paper)
    fail "No copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] in s3 found" if paper.public_url.nil?
    pdf = Excon.get(paper.public_url)
    fail 'Couldn\'t download PDF' if pdf.status != 200
    meta = Excon.put(tika_endpoint,
                     body: pdf.body,
                     headers: { 'Content-Type' => 'application/pdf', 'Accept' => 'application/json' })
    fail 'Couldn\'t get meta data' if meta.status != 200

    JSON.parse(meta.body)['date']
  end
end