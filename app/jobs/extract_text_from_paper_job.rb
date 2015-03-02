class ExtractTextFromPaperJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    logger.info "Extracting Text of the Paper [#{paper.body.state} #{paper.full_reference}]"

    if !Rails.configuration.x.tika_server.blank?
      text = extract_tika(paper)
    else
      text = extract_local(paper)
    end

    fail "Can't extract text from Paper [#{paper.body.state} #{paper.full_reference}]" if text.blank?

    text = clean_text(text)

    paper.contents = text
    paper.save

    ContainsTableJob.perform_later(paper)
    ExtractOriginatorsJob.perform_later(paper)
    ExtractAnswerersJob.perform_later(paper)
  end

  def extract_local(paper)
    # FIXME: not multi host capable
    fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found" unless File.exist?(paper.local_path)

    tempdir = Dir.mktmpdir
    Docsplit.extract_text(paper.local_path, ocr: false, output: tempdir)
    resultfile = "#{tempdir}/#{paper.reference}.txt" # fixme, use last of localpath
    return false unless File.exist?(resultfile)
    File.read resultfile
  ensure
    FileUtils.remove_entry_secure tempdir if File.exist?(tempdir)
  end

  def extract_tika(paper)
    fail "No copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] in s3 found" if paper.public_url.nil?
    pdf = Excon.get(paper.public_url)
    fail 'Couldn\'t download PDF' if pdf.status != 200
    text = Excon.put(Rails.configuration.x.tika_server,
                     body: pdf.body,
                     headers: { 'Content-Type' => 'application/pdf', 'Accept' => 'text/plain' })
    fail 'Couldn\'t get text' if text.status != 200
    # reason for force_encoding: https://github.com/excon/excon/issues/189
    text.body.force_encoding('utf-8').strip
  end

  def clean_text(text)
    # "be-\npflanzt" -> "bepflanzt\n", "be- \npflanzt" -> "bepflanzt\n"
    text.gsub!(/(\p{L}+)\-\p{Zs}*\n(\p{L}+)/m, "\\1\\2\n")
    # soft hyphen
    text.gsub!(/\u00AD/, '')
    text
  end
end