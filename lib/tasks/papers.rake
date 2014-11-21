namespace :papers do

  desc 'switch logger to stdout'
  task to_stdout: :environment do
   Rails.logger = Logger.new(STDOUT)
  end

  desc 'Upload papers to s3'
  task upload: :environment do
    limit = ENV['limit'] || 50
    f = FetchPapersJob.new
    @papers = Paper.where(downloaded_at: nil).limit(limit)
    @papers.each do |paper|
      Rails.logger.info "Uploading #{paper.body.state} #{paper.full_reference}"
      f.store_paper(paper)
    end
  end

end
