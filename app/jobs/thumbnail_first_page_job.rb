class ThumbnailFirstPageJob < ActiveJob::Base
  queue_as :store

  def perform(paper, force: false)
    logger.info "Creating thumbnail of first page of the Paper [#{paper.body.state} #{paper.full_reference}]"

    # FIXME: not multi host capable
    unless File.exist? paper.local_path
      fail "No local copy of the PDF of Paper [#{paper.body.state} #{paper.full_reference}] found"
    end

    if !AppStorage.bucket.files.head(paper.thumbnail_path).nil? && !force
      logger.info "Thumbnail for Paper [#{paper.body.state} #{paper.full_reference}] already exists in Storage"
      return
    end

    image_optim = ImageOptim.new(nice: 20, skip_missing_workers: true, pngout: false, svgo: false)

    imagedata = `pdftoppm -png -l 1 -singlefile -r 600 -scale-to-y 445 -scale-to-x 315 -thinlinemode shape #{paper.local_path}`
    imagedata = image_optim.optimize_image_data(imagedata) || imagedata

    file = AppStorage.bucket.files.new(key: paper.thumbnail_path, public: true, body: imagedata)
    file.save
  end
end