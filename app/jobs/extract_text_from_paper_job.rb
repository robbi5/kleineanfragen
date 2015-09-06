class ExtractTextFromPaperJob < PaperJob
  queue_as :meta

  def perform(paper, options = {})
    options.reverse_merge!(method: :tika)
    logger.info "Extracting Text of the Paper [#{paper.body.state} #{paper.full_reference}]"

    if !Rails.configuration.x.tika_server.blank? && options[:method] == :tika
      text = extract_tika(paper)
    elsif !Abbyy.application_id.blank? && options[:method] == :abbyy
      text = extract_abbyy(paper)
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
    DeterminePaperTypeJob.perform_later(paper)
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

  def tika_endpoint
    Addressable::URI.parse(Rails.configuration.x.tika_server).join('./tika').normalize.to_s
  end

  def extract_tika(paper)
    fail "No copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] in s3 found" if paper.public_url.nil?
    pdf = Excon.get(paper.public_url, read_timeout: 120, connect_timeout: 90)
    fail 'Couldn\'t download PDF' if pdf.status != 200
    text = Excon.put(tika_endpoint,
                     body: pdf.body,
                     headers: { 'Content-Type' => 'application/pdf', 'Accept' => 'text/plain' })
    fail 'Couldn\'t get text' if text.status != 200
    # reason for force_encoding: https://github.com/excon/excon/issues/189
    t = text.body.force_encoding('utf-8').strip
    # remove weird pdf control things
    t.gsub(/\n\n<<\n.+\n>> (?:setdistillerparams|setpagedevice)/m, '')
  end

  def extract_abbyy(paper)
    fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found" unless File.exist?(paper.local_path)
    client = Abbyy::Client.new
    client.process_image paper.local_path, profile: 'documentArchiving', exportFormat: 'txtUnstructured', language: 'German'
    while %w(Queued InProgress).include?(client.task[:status])
      sleep(client.task[:estimatedProcessingTime].to_i)
      client.get_task_status
    end
    fail "Task failed: #{client.task.inspect}" if client.task[:status] != 'Completed'
    text = client.get
    fail 'Couldn\'t get text' if text.code != 200
    text.body.force_encoding('utf-8').strip
  end

  def clean_text(text)
    # "be-\npflanzt" -> "bepflanzt\n", "be- \npflanzt" -> "bepflanzt\n"
    text.gsub!(/(\p{L}+)\-\p{Zs}*\r?\n\n?(\p{L}+)/m, "\\1\\2\n")
    # soft hyphen
    text.gsub!(/\u00AD/, '')
    # windows newlines
    text.gsub!(/\r\n/, "\n")
    text
  end
end