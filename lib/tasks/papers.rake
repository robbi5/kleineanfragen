namespace :papers do

  desc 'switch logger to stdout'
  task to_stdout: :environment do
   Rails.logger = Logger.new(STDOUT)
  end

  desc 'Download and store papers in s3'
  task store_all: :environment do
    limit = ENV['limit'] || 50
    papers = Paper.where(downloaded_at: nil).limit(limit)
    papers.each do |paper|
      Rails.logger.info "Adding job for uploading paper [#{paper.body.state} #{paper.full_reference}]"
      StorePaperPDFJob.perform_later(paper)
    end
  end

  desc 'Extract text from papers'
  task extract_all: :environment do
    limit = ENV['limit'] || 50
    papers = Paper.where(contents: nil).limit(limit)
    papers.each do |paper|
      Rails.logger.info "Adding job for extracting text of paper [#{paper.body.state} #{paper.full_reference}]"
      ExtractTextFromPaperJob.perform_later(paper)
    end
  end

  desc 'Extract names from papers'
  task parse_all: :environment do
    limit = ENV['limit'] || 50
    papers = Paper.find_by_sql(
      ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Person') WHERE o.id IS NULL LIMIT ?", limit])
    papers.each do |paper|
      Rails.logger.info "Adding job for extracting names from paper [#{paper.body.state} #{paper.full_reference}]"
      ExtractPeopleNamesJob.perform_later(paper)
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
    ImportNewPapersJob.perform_later(body, args[:legislative_term])
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

  desc 'Extract names from paper'
  task :extract_names, [:state, :legislative_term, :reference] => [:environment] do |_t, args|
    body = Body.find_by_state(args[:state])
    paper = Paper.where(body: body, legislative_term: args[:legislative_term], reference: args[:reference]).first
    Rails.logger.info "Adding job for extracting names of paper [#{paper.body.state} #{paper.full_reference}]"
    ExtractPeopleNamesJob.perform_later(paper)
  end
end
