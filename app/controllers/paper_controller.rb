class PaperController < ApplicationController
  before_filter :find_body, only: [:show, :viewer]
  before_filter :find_legislative_term, only: [:show, :viewer]
  before_filter :find_paper, only: [:show, :viewer]
  before_filter :redirect_old_slugs, only: [:show]

  def show
    if stale?(@paper, public: true)
      respond_to do |format|
        format.html
        format.pdf { redirect_to @paper.url }
        format.txt { render plain: @paper.contents }
      end
    end
  end

  def viewer
    @paper_pdf_url = @paper.public_url
    if !@paper.downloaded_at.nil? && !@paper_pdf_url.blank?
      render :viewer, layout: false
      # return redirect_to "https://mozilla.github.io/pdf.js/web/viewer.html?file=#{public_url}"
    else
      render :viewer_notavailable, layout: false
    end
  end

  def search
    @term = params[:q].presence
    @conditions = {}
    @conditions[:contains_table] = true if params[:table].present?
    redirect_to root_url if @term.blank? && @conditions.blank?

    @bodies = Body.all.map { |body| OpenStruct.new(name: body.name, state: body.state) }
    if params[:body].present?
      @conditions[:body] = @bodies.select { |body| params[:body].include? body.state }.map(&:state)
      @conditions.delete :body if params[:body].include? ''
    end

    query = Paper.search (@term || '*'),
                         where: @conditions,
                         fields: ['title^10', :contents],
                         page: params[:page],
                         per_page: 10,
                         highlight: { tag: '<mark>' },
                         facets: [:contains_table, :body],
                         smart_facets: true,
                         execute: false,
                         misspellings: false

    # boost newer papers
    unboosted_query = query.body[:query]
    query.body[:query] = {
      function_score: {
        query: unboosted_query,
        functions: [
          { boost_factor: 1 },
          {
            gauss: {
              published_at: {
                scale: '4w'
              }
            }
          }
        ],
        score_mode: 'sum'
      }
    }

    query.body[:highlight][:fields]['contents.analyzed'] = {
      'type' => 'fvh',
      'fragment_size' => 250,
      'number_of_fragments' => 1,
      'no_match_size' => 250
    }
    @papers = query.execute
  end

  def autocomplete
    render json: Paper.search(params[:q], fields: [{ title: :text_start }], limit: 5).map(&:autocomplete_data)
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
    canonical_path = paper_path(@body, @legislative_term, @paper, { format: mime_extension(request.format) })
    if request.path != canonical_path
      return redirect_to canonical_path, status: :moved_permanently
    end
  end
end
