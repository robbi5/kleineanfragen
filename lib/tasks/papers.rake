namespace :papers do
  desc 'switch logger to stdout'
  task to_stdout: :environment do
    Rails.logger = Logger.new(STDOUT)
  end

  desc 'Download and store papers in s3'
  task store_all: :environment do
    limit = ENV['limit'] || 50
    papers = Paper.where(downloaded_at: nil).limit(limit)
    papers.find_each do |paper|
      Rails.logger.info "Adding job for uploading paper [#{paper.body.state} #{paper.full_reference}]"
      StorePaperPDFJob.perform_later(paper)
    end
  end

  desc 'Extract text from papers'
  task extract_all: :environment do
    limit = ENV['limit'] || 50
    papers = Paper.where(contents: nil).limit(limit)
    papers.find_each do |paper|
      Rails.logger.info "Adding job for extracting text of paper [#{paper.body.state} #{paper.full_reference}]"
      ExtractTextFromPaperJob.perform_later(paper)
    end
  end

  desc 'Extract originators from papers'
  task parse_all: :environment do
    limit = ENV['limit'] || 50
    papers = Paper.find_by_sql(
      ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Person') WHERE o.id IS NULL LIMIT ?", limit])
    papers.each do |paper|
      Rails.logger.info "Adding job for extracting originators from paper [#{paper.body.state} #{paper.full_reference}]"
      ExtractOriginatorsJob.perform_later(paper)
    end
  end

  desc 'Import single paper'
  task :import, [:state, :legislative_term, :reference] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    Rails.logger.info "Adding job for importing single paper [#{body.state} #{args[:legislative_term]}/#{args[:reference]}]"
    ImportPaperJob.perform_later(body, args[:legislative_term], args[:reference])
  end

  desc 'Import new papers'
  task :import_new, [:state, :legislative_term] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    Rails.logger.info "Adding job for importing new papers [#{body.state} #{args[:legislative_term]}]"
    job_id = ImportNewPapersJob.perform_async(body, args[:legislative_term])
    puts ({ scraper_result_id: job_id }).to_json
  end

  desc 'Download and store paper in s3'
  task :store, [:state, :legislative_term, :reference] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    paper = Paper.where(body: body, legislative_term: args[:legislative_term], reference: args[:reference]).first
    Rails.logger.info "Adding job for uploading paper [#{paper.body.state} #{paper.full_reference}]"
    StorePaperPDFJob.perform_later(paper)
  end

  desc 'Extract text from paper'
  task :extract_text, [:state, :legislative_term, :reference] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    paper = Paper.where(body: body, legislative_term: args[:legislative_term], reference: args[:reference]).first
    Rails.logger.info "Adding job for extracting text of paper [#{paper.body.state} #{paper.full_reference}]"
    ExtractTextFromPaperJob.perform_later(paper)
  end

  desc 'Extract originators from paper'
  task :extract_originators, [:state, :legislative_term, :reference] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    paper = Paper.where(body: body, legislative_term: args[:legislative_term], reference: args[:reference]).first
    Rails.logger.info "Adding job for extracting originators of paper [#{paper.body.state} #{paper.full_reference}]"
    ExtractOriginatorsJob.perform_later(paper)
  end

  desc 'Extract answerers from paper'
  task :extract_answerers, [:state, :legislative_term, :reference] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    paper = Paper.where(body: body, legislative_term: args[:legislative_term], reference: args[:reference]).first
    Rails.logger.info "Adding job for extracting answerers of paper [#{paper.body.state} #{paper.full_reference}]"
    ExtractAnswerersJob.perform_later(paper)
  end

  desc 'Reimport unreviewed PDFs'
  task :reimport_pdfs, :environment do
    Rails.logger.info 'Adding job for reimporting PDFs'
    ReimportPapersPDFJob.perform_later
  end

  desc 'Send Search Subscription Emails'
  task :reimport_pdfs, :environment do
    Rails.logger.info 'Adding job for sending search subscription emails'
    SendSearchSubscriptionsJob.perform_later
  end
end
