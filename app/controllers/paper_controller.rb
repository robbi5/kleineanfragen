class PaperController < ApplicationController
  before_filter :find_body, only: [:show, :viewer]
  before_filter :find_legislative_term, only: [:show, :viewer]
  before_filter :find_paper, only: [:show, :viewer]
  before_filter :redirect_old_slugs, only: [:show]

  def show
    if stale?(@paper, public: true)
      respond_to do |format|
        format.html
        format.pdf { redirect_to @paper.download_url }
        format.txt { render plain: @paper.contents }
      end
    end
  end

  def viewer
    @paper_pdf_url = @paper.public_url
    if !@paper.downloaded_at.nil? && !@paper_pdf_url.blank?
      render :viewer, layout: false
    else
      render :viewer_notavailable, layout: false
    end
  end

  def recent
    @days = 14
    @papers = Paper.where('published_at >= ?', Date.today - @days.days)
              .order(published_at: :desc, reference: :desc)
              .page(params[:page])
    @recent = @papers.to_a.group_by(&:published_at)
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end

  def redirect_by_id
    @paper = Paper.find(params[:paper].to_i)
    redirect_to paper_path(@paper.body, @paper.legislative_term, @paper)
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_legislative_term
    @legislative_term = params[:legislative_term].to_i
  end

  def find_paper
    if params[:paper] =~ /^\d+$/
      return find_paper_by_reference(params[:paper])
    end

    begin
      @paper = Paper.where(body: @body, legislative_term: @legislative_term).friendly.find params[:paper]
    rescue ActiveRecord::RecordNotFound => e
      if params[:paper] =~ /^(\d+)\-/
        return find_paper_by_reference Regexp.last_match[1]
      end
      raise e
    end
  end

  def find_paper_by_reference(reference)
    @paper = Paper.where(body: @body, legislative_term: @legislative_term, reference: reference).first
    fail ActiveRecord::RecordNotFound if @paper.nil?
  end

  def redirect_old_slugs
    canonical_path = paper_path(@body, @legislative_term, @paper, format: mime_extension(request.format))
    if request.path != canonical_path
      return redirect_to canonical_path, status: :moved_permanently
    end
  end
end
