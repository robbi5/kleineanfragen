class PaperController < ApplicationController
  before_filter :find_body, only: [:show]
  before_filter :find_legislative_term, only: [:show]
  before_filter :find_paper, only: [:show]

  def show
    respond_to do |format|
      format.html
      format.pdf { redirect_to @paper.url }
    end
  end

  def search
    @term = params[:q]
    @papers = Paper.search @term, page: params[:page], per_page: 10
  end

  def autocomplete
    render json: Paper.search(params[:q], fields: [{title: :text_start}], limit: 5).map(&:autocomplete_data)
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

    redirect_old_slugs
  end

  def find_paper_by_reference(reference)
    @paper = Paper.where(body: @body, legislative_term: @legislative_term, reference: reference).first
    raise ActiveRecord::RecordNotFound if @paper.nil?

    redirect_old_slugs
  end

  def redirect_old_slugs
    canonical_path = paper_path(@body, @legislative_term, @paper, {format: mime_extension(request.format)})
    if request.path != canonical_path
      return redirect_to canonical_path, :status => :moved_permanently
    end
  end
end
