class PaperController < ApplicationController
  before_action :find_body, only: [:show, :viewer, :report, :send_report, :update]
  before_action :find_legislative_term, only: [:show, :viewer, :report, :send_report, :update]
  before_action :find_paper, only: [:show, :viewer, :report, :send_report, :update]
  before_action :redirect_old_slugs, only: [:show]

  def show
    if stale?(@paper, public: true)
      respond_to do |format|
        format.html
        format.pdf do
          raise ActionController::RoutingError.new('Download URL not found') if @paper.download_url.nil?
          redirect_to @paper.download_url
        end
        format.txt { render plain: @paper.contents }
        format.json
      end
    end
  end

  def viewer
    if stale?(@paper, public: true)
      @paper_pdf_url = @paper.public_url
      if !@paper.downloaded_at.nil? && !@paper_pdf_url.blank?
        render :viewer, layout: false
      else
        render :viewer_notavailable, layout: false
      end
    end
  end

  def recent
    respond_to do |format|
      format.atom { return render status: 410 }
      format.html { return render status: 410, body: nil }
    end
  end

  def redirect_by_id
    @paper = Paper.find(params[:paper].to_i)
    redirect_to paper_path(@paper.body, @paper.legislative_term, @paper, format: mime_extension(request.format))
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
    if @paper.nil?
      r = PaperRedirect.where(body: @body, legislative_term: @legislative_term, reference: reference).first
      if r.nil?
        fail ActiveRecord::RecordNotFound
      end
      return redirect_to paper_path(r.body, r.legislative_term, r.paper), status: :moved_permanently
    end
  end

  def redirect_old_slugs
    canonical_path = paper_path(@body, @legislative_term, @paper, format: mime_extension(request.format))
    if request.path != canonical_path
      return redirect_to canonical_path, status: :moved_permanently
    end
  end
end